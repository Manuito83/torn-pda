import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: new Drawer(),
      appBar: AppBar(
        title: Text('Friends'),
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState =
            context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
              //color: _themeProvider.buttonText,
            ),
            onPressed: () {
              //_showAddDialog(context);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              //color: _themeProvider.buttonText,
            ),
            onPressed: () async {
              /*var updateResult = await _targetsProvider.updateAllTargets();
              if (updateResult.success) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text(updateResult.numberSuccessful > 0
                        ? 'Successfully updated '
                        '${updateResult.numberSuccessful} '
                        'targets!'
                        : 'No targets to update!'),
                  ),
                );
              } else {
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'Update with errors: ${updateResult.numberErrors} errors '
                          'out of ${updateResult.numberErrors + updateResult.numberSuccessful} '
                          'total targets!',
                    ),
                  ),
                );
              }*/
            },
          ),
/*          PopupMenuButton<TargetSortPopup>(
            icon: Icon(
              Icons.sort,
            ),
            onSelected: _selectSortPopup,
            itemBuilder: (BuildContext context) {
              return _popupChoices.map((TargetSortPopup choice) {
                return PopupMenuItem<TargetSortPopup>(
                  value: choice,
                  child: Text(choice.description),
                );
              }).toList();
            },
          ),*/
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
/*              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TargetsBackupPage(),
                ),
              );*/
            },
          ),
        ],
      ),


      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        child: Column(
          children: <Widget>[
            Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              //controller: _searchController,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: "Search",
                                prefixIcon: Icon(
                                  Icons.search,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
/*            Flexible(
              child: Consumer<TargetsProvider>(
                builder: (context, targetsModel, child) => TargetsList(
                  targets: targetsModel.allTargets,
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
