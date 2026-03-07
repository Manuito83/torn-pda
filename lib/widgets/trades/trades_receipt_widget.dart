import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:torn_pda/models/trades/trade_price_provider.dart';
import 'package:torn_pda/models/trades/trade_sync_item.dart';
import 'package:torn_pda/models/trades/torn_exchange/torn_exchange_receipt.dart';
import 'package:torn_pda/models/trades/torn_w3b/torn_w3b_receipt.dart';
import 'package:torn_pda/utils/external/torn_exchange_comm.dart';
import 'package:torn_pda/utils/external/torn_w3b_comm.dart';

class TradeReceiptRow extends StatefulWidget {
  final Widget clipboardIcon;
  final TradePriceProvider tradePriceProvider;
  final String providerName;
  final TradeSyncReceiptRequest? receiptRequest;
  final TradeSyncReceiptData? initialReceiptData;
  final ValueChanged<TradeSyncReceiptData>? onReceiptUpdated;

  const TradeReceiptRow({
    super.key,
    required this.clipboardIcon,
    required this.tradePriceProvider,
    required this.providerName,
    required this.receiptRequest,
    this.initialReceiptData,
    this.onReceiptUpdated,
  });

  @override
  State<TradeReceiptRow> createState() => _TradeReceiptRowState();
}

class _TradeReceiptRowState extends State<TradeReceiptRow> {
  TradeSyncReceiptData? _receiptData;

  static const ttColor = Color(0xffd186cf);
  static const w3bColor = Color(0xff4dd0e1);

  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _receiptData = widget.initialReceiptData;
  }

  @override
  void didUpdateWidget(covariant TradeReceiptRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialReceiptData != null && widget.initialReceiptData != oldWidget.initialReceiptData) {
      _receiptData = widget.initialReceiptData;
    }
  }

  void _copyToClipboard(String content, String successMessage, {int seconds = 5}) {
    Clipboard.setData(ClipboardData(text: content));
    BotToast.showText(
      text: successMessage,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.green,
      duration: Duration(seconds: seconds),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Future<void> _fetchReceipt() async {
    if (_receiptData != null && _receiptData!.url.isNotEmpty) {
      return;
    }
    if (_isFetching) {
      return;
    }
    if (widget.receiptRequest == null) {
      _showErrorToast('There is no receipt information available for this trade.');
      return;
    }

    setState(() => _isFetching = true);

    try {
      final receipt = await _requestReceipt(widget.receiptRequest!);

      if (receipt.serverError) {
        _showErrorToast(
          receipt.serverErrorReason.isNotEmpty
              ? receipt.serverErrorReason
              : 'There was an error getting your receipt, no information copied!',
        );
      } else {
        setState(() {
          _receiptData = receipt;
        });
        widget.onReceiptUpdated?.call(receipt);
      }
    } catch (e) {
      _showErrorToast('Error getting your receipt: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<TradeSyncReceiptData> _requestReceipt(TradeSyncReceiptRequest request) async {
    switch (widget.tradePriceProvider) {
      case TradePriceProvider.tornExchange:
        final pricedItems = request.items.where((item) => item.price != null).toList();
        final receipt = await TornExchangeComm.getReceipt(
          TornExchangeReceiptOutModel(
            ownerUsername: request.ownerUsername,
            ownerUserId: request.ownerUserId,
            sellerUsername: request.sellerUsername,
            prices: pricedItems.map((item) => item.price ?? 0).toList(),
            itemQuantities: pricedItems.map((item) => item.quantity).toList(),
            itemNames: pricedItems.map((item) => item.name).toList(),
          ),
        );

        if (receipt.serverError) {
          return TradeSyncReceiptData(
            serverError: true,
            serverErrorReason: 'There was an error getting your ${widget.providerName} receipt.',
          );
        }

        final url = 'https://www.tornexchange.com/receipt/${receipt.receiptId}';
        var message = receipt.tradeMessage;
        if (message.isEmpty) {
          message = _defaultReceiptMessage(url);
        }

        return TradeSyncReceiptData(
          receiptId: receipt.receiptId,
          message: message,
          url: url,
          canEdit: false,
        );
      case TradePriceProvider.tornW3b:
        final receipt = await TornW3bComm.generateReceipt(
          request.ownerUserId,
          TornW3bReceiptRequest(
            items: request.items
                .map(
                  (item) => TornW3bReceiptRequestItem(
                    itemId: item.itemId > 0 ? item.itemId : null,
                    name: item.itemId > 0 ? null : item.name,
                    quantity: item.quantity,
                  ),
                )
                .toList(),
            username: request.ownerUsername,
            tradeId: request.tradeId,
            includeMessage: true,
          ),
        );

        final receiptItems = _buildW3bTradeSyncItems(
          receipt.receipt.items,
          request.items,
        );

        return TradeSyncReceiptData(
          receiptId: _receiptIdFromUrl(receipt.receiptUrl),
          message: _defaultReceiptMessage(receipt.receiptUrl),
          url: receipt.receiptUrl,
          totalValue: receipt.receipt.totalValue,
          canEdit: true,
          items: receiptItems,
        );
      case TradePriceProvider.none:
        return TradeSyncReceiptData(
          serverError: true,
          serverErrorReason: 'No trade sync provider is active.',
        );
    }
  }

  Future<void> _editReceipt() async {
    await _fetchReceipt();

    if (_receiptData == null || !_receiptData!.canEdit) {
      return;
    }

    if (_receiptData!.receiptId.isEmpty) {
      _showErrorToast('Receipt ID not available, unable to edit prices.');
      return;
    }

    final updates = await _showEditDialog(_receiptData!);

    if (updates == null || updates.isEmpty) {
      return;
    }

    setState(() => _isFetching = true);

    try {
      final response = await TornW3bComm.updateReceipt(
        _receiptData!.receiptId,
        TornW3bReceiptUpdateRequest(items: updates),
      );

      final mergedItems = List<TradeSyncItem>.from(_receiptData!.items);
      for (final updated in response.data.receipt.items) {
        final responseItem = TradeSyncItem(
          itemId: updated.itemId,
          name: updated.name,
          quantity: updated.quantity,
          price: updated.priceUsed > 0
              ? updated.priceUsed
              : (updated.quantity > 0 && updated.totalValue > 0)
                  ? (updated.totalValue / updated.quantity).round()
                  : 0,
          totalPrice: updated.totalValue,
        );

        final index = mergedItems.indexWhere((item) => item.itemId == responseItem.itemId && item.itemId > 0);
        if (index != -1) {
          mergedItems[index] = responseItem;
        }
      }

      final updatedUrl = response.data.receiptUrl.isNotEmpty ? response.data.receiptUrl : _receiptData!.url;

      setState(() {
        _receiptData = TradeSyncReceiptData(
          receiptId: _receiptData!.receiptId,
          message: _defaultReceiptMessage(updatedUrl),
          url: updatedUrl,
          totalValue: response.data.receipt.totalValue,
          canEdit: true,
          items: mergedItems,
        );
      });
      widget.onReceiptUpdated?.call(_receiptData!);

      BotToast.showText(
        text: '${widget.providerName} receipt updated successfully!',
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.green,
        duration: const Duration(seconds: 4),
        contentPadding: const EdgeInsets.all(10),
      );
    } catch (e) {
      _showErrorToast('Error updating receipt: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<List<TornW3bReceiptPriceUpdateItem>?> _showEditDialog(TradeSyncReceiptData receiptData) async {
    final pendingPrices = List<int>.from(receiptData.items.map((item) => item.price));
    String validationError = '';

    return showDialog<List<TornW3bReceiptPriceUpdateItem>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit ${widget.providerName} receipt'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'You can update per-item prices for this receipt. TornW3B allows editing receipts for up to 6 hours after creation.',
                      ),
                      const SizedBox(height: 12),
                      for (int index = 0; index < receiptData.items.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${receiptData.items[index].name} x${receiptData.items[index].quantity}'),
                              const SizedBox(height: 4),
                              TextFormField(
                                initialValue: pendingPrices[index].toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price per item',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value.trim());
                                  pendingPrices[index] = parsed ?? -1;
                                },
                              ),
                            ],
                          ),
                        ),
                      if (validationError.isNotEmpty)
                        Text(
                          validationError,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updates = <TornW3bReceiptPriceUpdateItem>[];

                    for (int index = 0; index < receiptData.items.length; index++) {
                      final item = receiptData.items[index];
                      final pendingPrice = pendingPrices[index];

                      if (pendingPrice < 0) {
                        setStateDialog(() {
                          validationError = 'All prices must be valid non-negative integers.';
                        });
                        return;
                      }

                      if (item.itemId <= 0) {
                        setStateDialog(() {
                          validationError = 'Some items do not have a valid item ID in the receipt.';
                        });
                        return;
                      }

                      if (pendingPrice != item.price) {
                        updates.add(
                          TornW3bReceiptPriceUpdateItem(
                            itemId: item.itemId,
                            price: pendingPrice,
                          ),
                        );
                      }
                    }

                    Navigator.of(context).pop(updates);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorToast(String message) {
    BotToast.showText(
      text: message,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.redAccent,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  String _defaultReceiptMessage(String url) {
    return 'Thanks for the trade! Your ${widget.providerName} receipt is available at $url';
  }

  String _receiptIdFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) {
      return '';
    }

    return uri.pathSegments.last;
  }

  List<TradeSyncItem> _buildW3bTradeSyncItems(
    List<TornW3bReceiptResponseItem> responseItems,
    List<TradeSyncReceiptRequestItem> requestItems,
  ) {
    final receiptItems = <TradeSyncItem>[];

    for (int index = 0; index < responseItems.length; index++) {
      final responseItem = responseItems[index];
      final requestItem = index < requestItems.length ? requestItems[index] : null;

      final itemId = responseItem.itemId > 0 ? responseItem.itemId : (requestItem?.itemId ?? 0);
      final quantity = responseItem.quantity > 0 ? responseItem.quantity : (requestItem?.quantity ?? 0);
      final totalPrice = responseItem.totalValue;
      final resolvedPrice = responseItem.priceUsed > 0
          ? responseItem.priceUsed
          : (quantity > 0 && totalPrice > 0)
              ? (totalPrice / quantity).round()
              : 0;

      receiptItems.add(
        TradeSyncItem(
          itemId: itemId,
          name: responseItem.name.isNotEmpty ? responseItem.name : (requestItem?.name ?? ''),
          quantity: quantity,
          price: resolvedPrice,
          totalPrice: totalPrice > 0 ? totalPrice : resolvedPrice * quantity,
        ),
      );
    }

    return receiptItems;
  }

  Color get _providerColor => widget.tradePriceProvider == TradePriceProvider.tornW3b ? w3bColor : ttColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: widget.clipboardIcon,
        ),
        SizedBox(
          height: 23,
          width: 23,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 23,
            icon: Icon(
              Icons.receipt_long_outlined,
              size: 23,
              color: _providerColor,
            ),
            onPressed: () async {
              await _fetchReceipt();
              if (_receiptData != null) {
                _copyToClipboard(
                  _receiptData!.message,
                  'Receipt copied to clipboard:\n\n${_receiptData!.message}',
                  seconds: 8,
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 23,
          width: 23,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 23,
            icon: Icon(
              MdiIcons.webCheck,
              size: 23,
              color: _providerColor,
            ),
            onPressed: () async {
              await _fetchReceipt();
              if (_receiptData != null) {
                _copyToClipboard(
                  _receiptData!.url,
                  'Receipt URL copied to clipboard:\n\n${_receiptData!.url}',
                  seconds: 5,
                );
              }
            },
          ),
        ),
        if (widget.tradePriceProvider.supportsReceiptEditing) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 23,
            width: 23,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 23,
              icon: Icon(
                Icons.edit_note,
                size: 23,
                color: _providerColor,
              ),
              onPressed: _isFetching ? null : _editReceipt,
            ),
          ),
        ],
      ],
    );
  }
}
