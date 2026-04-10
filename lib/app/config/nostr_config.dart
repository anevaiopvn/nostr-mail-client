class NostrConfig {
  static const bootstrapRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    // 'wss://relay.nostr.band',
    'wss://relay.primal.net',
    'wss://relay.coinos.io',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
    'wss://nostr-01.yakihonne.com',
  ];

  static const recommendedInboxOutboxRelays = [
    'wss://relay.damus.io',
    'wss://relay.camelus.app',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
    'wss://relay.primal.net',
  ];

  static const recommendedDmRelays = [
    'wss://auth.nostr1.com',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
  ];

  static const recommendedBlossomServers = [
    'https://blossom.yakihonne.com',
    'https://blossom-01.uid.ovh',
    'https://blossom-02.uid.ovh',
    'https://blossom.primal.net',
  ];

  static const recommendedBridges = ['uid.ovh'];
}
