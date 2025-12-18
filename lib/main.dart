import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

void main() {
  runApp(const NFCTesterApp());
}

class NFCTesterApp extends StatelessWidget {
  const NFCTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Tesztelő',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const NFCHomePage(),
    );
  }
}

class NFCHomePage extends StatefulWidget {
  const NFCHomePage({super.key});

  @override
  State<NFCHomePage> createState() => _NFCHomePageState();
}

class _NFCHomePageState extends State<NFCHomePage> {
  bool? _isNfcAvailable;
  String _statusMessage = 'NFC állapot ellenőrzése...';

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
      _statusMessage = isAvailable
          ? 'NFC elérhető és működik ✓'
          : 'NFC nem elérhető vagy ki van kapcsolva ✗';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Tesztelő'), centerTitle: true),
      body: Column(
        children: [
          // Állapot információ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _isNfcAvailable == true
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Column(
              children: [
                Icon(
                  _isNfcAvailable == true ? Icons.check_circle : Icons.error,
                  size: 48,
                  color: _isNfcAvailable == true ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _checkNfcAvailability,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Újraellenőrzés'),
                ),
              ],
            ),
          ),

          // Módok választása
          Expanded(
            child: _isNfcAvailable == true
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Válassz egy módot:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Olvasó mód
                      _ModeCard(
                        title: 'Olvasó Mód',
                        subtitle: 'NFC címkék és adatok fogadása',
                        icon: Icons.nfc,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NFCReaderPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Író mód
                      _ModeCard(
                        title: 'Író Mód',
                        subtitle: 'Adat írása NFC címkére',
                        icon: Icons.edit,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NFCWriterPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Emulátor mód
                      _ModeCard(
                        title: 'Peer-to-Peer Mód',
                        subtitle: 'Két telefon közötti adatcsere',
                        icon: Icons.swap_horiz,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NFCP2PPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, size: 64, color: Colors.orange),
                        const SizedBox(height: 20),
                        const Text(
                          'Az NFC nem használható',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ellenőrizd, hogy:\n• Az eszköz támogatja az NFC-t\n• Az NFC be van kapcsolva a beállításokban',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// OLVASÓ MÓD
class NFCReaderPage extends StatefulWidget {
  const NFCReaderPage({super.key});

  @override
  State<NFCReaderPage> createState() => _NFCReaderPageState();
}

class _NFCReaderPageState extends State<NFCReaderPage> {
  String _status = 'Várakozás...';
  List<String> _dataLog = [];
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _startReading();
  }

  void _startReading() {
    setState(() {
      _isReading = true;
      _status =
          'Olvasásra kész. Érintsd egy NFC címkéhez vagy másik telefonhoz...';
      _dataLog.add(
        '[${DateTime.now().toString().substring(11, 19)}] Olvasó mód elindítva',
      );
    });

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _status = 'NFC címke detektálva!';
          _dataLog.add(
            '[${DateTime.now().toString().substring(11, 19)}] NFC címke észlelve',
          );
        });

        // Tag információk kiolvasása
        final tagData = tag.data;
        setState(() {
          _dataLog.add('Tag típus: ${tagData.keys.join(", ")}');
        });

        // NDEF adatok olvasása
        if (tagData.containsKey('ndef')) {
          final ndefData = tagData['ndef'];
          if (ndefData != null && ndefData is Map) {
            final cachedMessage = ndefData['cachedMessage'];
            if (cachedMessage != null && cachedMessage is Map) {
              final records = cachedMessage['records'];
              if (records != null && records is List) {
                for (var record in records) {
                  if (record is Map && record.containsKey('payload')) {
                    final payload = record['payload'] as Uint8List;
                    final text = String.fromCharCodes(
                      payload.skip(3),
                    ); // Skip nyelv kód
                    setState(() {
                      _dataLog.add('Tartalom: $text');
                      _status = 'Sikeresen beolvasva: $text';
                    });
                  }
                }
              }
            }
          }
        }

        // ID kiolvasása
        if (tagData.containsKey('nfca')) {
          final nfcA = tagData['nfca'];
          if (nfcA != null && nfcA is Map && nfcA.containsKey('identifier')) {
            final id = nfcA['identifier'] as Uint8List;
            final idHex = id
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(':');
            setState(() {
              _dataLog.add('Tag ID: $idHex');
            });
          }
        }

        setState(() {
          _dataLog.add(
            '[${DateTime.now().toString().substring(11, 19)}] Olvasás befejezve\n',
          );
        });
      },
    );
  }

  void _stopReading() {
    NfcManager.instance.stopSession();
    setState(() {
      _isReading = false;
      _status = 'Olvasás leállítva';
      _dataLog.add(
        '[${DateTime.now().toString().substring(11, 19)}] Olvasó mód leállítva\n',
      );
    });
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olvasó Mód'),
        actions: [
          IconButton(
            icon: Icon(_isReading ? Icons.stop : Icons.play_arrow),
            onPressed: _isReading ? _stopReading : _startReading,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _isReading ? Colors.blue.shade100 : Colors.grey.shade200,
            child: Column(
              children: [
                Icon(
                  _isReading ? Icons.nfc : Icons.stop_circle,
                  size: 64,
                  color: _isReading ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 10),
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Napló',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dataLog.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Törlés'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                itemCount: _dataLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _dataLog[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ÍRÓ MÓD
class NFCWriterPage extends StatefulWidget {
  const NFCWriterPage({super.key});

  @override
  State<NFCWriterPage> createState() => _NFCWriterPageState();
}

class _NFCWriterPageState extends State<NFCWriterPage> {
  final TextEditingController _textController = TextEditingController();
  String _status = 'Írj be egy üzenetet, majd érintsd a címkéhez';
  bool _isWriting = false;

  void _writeToTag() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _status = 'Kérlek írj be egy üzenetet!';
      });
      return;
    }

    setState(() {
      _isWriting = true;
      _status = 'Várakozás NFC címkére...';
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            var ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              setState(() {
                _status = 'Ez a címke nem írható!';
                _isWriting = false;
              });
              NfcManager.instance.stopSession(errorMessage: 'Nem írható címke');
              return;
            }

            // NDEF üzenet létrehozása
            final message = NdefMessage([
              NdefRecord.createText(_textController.text),
            ]);

            // Írás
            await ndef.write(message);

            setState(() {
              _status = 'Sikeresen írva: "${_textController.text}"';
              _isWriting = false;
            });

            NfcManager.instance.stopSession();
          } catch (e) {
            setState(() {
              _status = 'Hiba írás közben: $e';
              _isWriting = false;
            });
            NfcManager.instance.stopSession(errorMessage: 'Írási hiba');
          }
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Hiba: $e';
        _isWriting = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Író Mód')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isWriting
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _isWriting ? Icons.nfc : Icons.edit,
                    size: 64,
                    color: _isWriting ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Üzenet írása címkére:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Írd be az üzenetet',
                hintText: 'pl: Teszt üzenet az NFC tesztelőtől',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isWriting ? null : _writeToTag,
              icon: const Icon(Icons.nfc),
              label: Text(
                _isWriting ? 'Várakozás címkére...' : 'Írás indítása',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Útmutató:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Írj be egy üzenetet a mezőbe'),
                    Text('2. Nyomd meg az "Írás indítása" gombot'),
                    Text('3. Érintsd a telefont egy írható NFC címkéhez'),
                    Text('4. Várd meg a megerősítést'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PEER-TO-PEER MÓD
class NFCP2PPage extends StatefulWidget {
  const NFCP2PPage({super.key});

  @override
  State<NFCP2PPage> createState() => _NFCP2PPageState();
}

class _NFCP2PPageState extends State<NFCP2PPage> {
  final TextEditingController _messageController = TextEditingController(
    text: 'Teszt üzenet ${DateTime.now().millisecondsSinceEpoch}',
  );
  String _status = 'Válassz egy módot';
  List<String> _log = [];
  bool _isActive = false;

  void _startSender() async {
    if (_messageController.text.isEmpty) {
      setState(() {
        _status = 'Adj meg egy üzenetet!';
      });
      return;
    }

    setState(() {
      _isActive = true;
      _status = 'Küldő mód: Érintsd a másik telefonhoz...';
      _log.add(
        '[${DateTime.now().toString().substring(11, 19)}] Küldő mód aktiválva',
      );
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            setState(() {
              _log.add(
                '[${DateTime.now().toString().substring(11, 19)}] Eszköz detektálva',
              );
            });

            var ndef = Ndef.from(tag);
            if (ndef != null && ndef.isWritable) {
              final message = NdefMessage([
                NdefRecord.createText(_messageController.text),
              ]);

              await ndef.write(message);

              setState(() {
                _status = 'Üzenet sikeresen elküldve!';
                _log.add(
                  '[${DateTime.now().toString().substring(11, 19)}] Üzenet elküldve: "${_messageController.text}"',
                );
                _isActive = false;
              });

              NfcManager.instance.stopSession();
            } else {
              setState(() {
                _status = 'Nem sikerült írni az eszközre';
                _log.add(
                  '[${DateTime.now().toString().substring(11, 19)}] Írási hiba - eszköz nem írható',
                );
                _isActive = false;
              });
              NfcManager.instance.stopSession(errorMessage: 'Nem írható');
            }
          } catch (e) {
            setState(() {
              _status = 'Hiba: $e';
              _log.add(
                '[${DateTime.now().toString().substring(11, 19)}] Hiba: $e',
              );
              _isActive = false;
            });
            NfcManager.instance.stopSession(errorMessage: 'Hiba történt');
          }
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Hiba: $e';
        _log.add('[${DateTime.now().toString().substring(11, 19)}] Hiba: $e');
        _isActive = false;
      });
    }
  }

  void _startReceiver() {
    setState(() {
      _isActive = true;
      _status = 'Fogadó mód: Érintsd a másik telefonhoz...';
      _log.add(
        '[${DateTime.now().toString().substring(11, 19)}] Fogadó mód aktiválva',
      );
    });

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _log.add(
            '[${DateTime.now().toString().substring(11, 19)}] Eszköz detektálva',
          );
        });

        final tagData = tag.data;

        if (tagData.containsKey('ndef')) {
          final ndefData = tagData['ndef'];
          if (ndefData != null && ndefData is Map) {
            final cachedMessage = ndefData['cachedMessage'];
            if (cachedMessage != null && cachedMessage is Map) {
              final records = cachedMessage['records'];
              if (records != null && records is List) {
                for (var record in records) {
                  if (record is Map && record.containsKey('payload')) {
                    final payload = record['payload'] as Uint8List;
                    final text = String.fromCharCodes(payload.skip(3));
                    setState(() {
                      _status = 'Üzenet fogadva!';
                      _log.add(
                        '[${DateTime.now().toString().substring(11, 19)}] Fogadott üzenet: "$text"',
                      );
                    });
                  }
                }
              }
            }
          }
        } else {
          setState(() {
            _log.add(
              '[${DateTime.now().toString().substring(11, 19)}] Nincs NDEF adat',
            );
          });
        }

        setState(() {
          _isActive = false;
        });

        NfcManager.instance.stopSession();
      },
    );
  }

  void _stop() {
    NfcManager.instance.stopSession();
    setState(() {
      _isActive = false;
      _status = 'Leállítva';
      _log.add(
        '[${DateTime.now().toString().substring(11, 19)}] Mód leállítva\n',
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peer-to-Peer Mód')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _isActive ? Colors.orange.shade100 : Colors.grey.shade100,
            child: Column(
              children: [
                Icon(
                  _isActive ? Icons.nfc : Icons.swap_horiz,
                  size: 64,
                  color: _isActive ? Colors.orange : Colors.grey,
                ),
                const SizedBox(height: 10),
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Elküldendő üzenet:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Üzenet',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isActive ? null : _startSender,
                        icon: const Icon(Icons.send),
                        label: const Text('Küldés'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isActive ? null : _startReceiver,
                        icon: const Icon(Icons.get_app),
                        label: const Text('Fogadás'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('Leállítás'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Napló',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _log.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Törlés'),
                    ),
                  ],
                ),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _log[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Használat két telefonnal:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. Első telefonon: Nyomd meg a "Küldés" gombot'),
                        Text(
                          '2. Második telefonon: Nyomd meg a "Fogadás" gombot',
                        ),
                        Text('3. Érintsd össze a két telefont (hátlapjukat)'),
                        Text('4. Várd meg az adatátvitelt'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
