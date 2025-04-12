Two replacement types:

    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {'comment': 'PDA-App'},
    );

    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: {...$params, 'comment': 'PDA-App'},
    );
 
