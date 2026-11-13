bool isPersonalQuickItemsPage(String url) => url.contains('item.php');

bool isFactionQuickItemsPage(String url) => url.contains('factions.php') && url.contains('tab=armoury');
