class NostrConfig {
  static const bootstrapRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
    'wss://relay.coinos.io',
    'wss://relay.nmail.li',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
    'wss://nostr-01.yakihonne.com',
  ];

  /// Popular relays used to broadcast signaling events (kinds 0, 10002,
  /// 10050, 10063) widely for maximum discoverability.
  static const popularRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
    'wss://relay.coinos.io',
    'wss://relay.nmail.li',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
    'wss://relay.camelus.app',
    'wss://nostr-01.yakihonne.com',
    'wss://nostr-02.yakihonne.com',
    'wss://purplepag.es',
  ];

  static const recommendedInboxOutboxRelays = [
    'wss://relay.damus.io',
    'wss://relay.camelus.app',
    'wss://relay.nmail.li',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
    'wss://relay.primal.net',
  ];

  static const recommendedDmRelays = [
    'wss://auth.nostr1.com',
    'wss://relay.nmail.li',
    'wss://nostr-01.uid.ovh',
    'wss://nostr-02.uid.ovh',
  ];

  static const recommendedBlossomServers = [
    'https://blossom.yakihonne.com',
    'https://blossom.nmail.li',
    'https://blossom-01.uid.ovh',
    'https://blossom-02.uid.ovh',
    'https://blossom.primal.net',
  ];

  static const recommendedBridges = ['uid.ovh'];
}
