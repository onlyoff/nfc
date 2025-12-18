import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';

void main() {
  runApp(const NFCTesterApp());
}

// Helper function to create text NDEF record
NdefRecord createTextRecord(String text, {String languageCode = 'en'}) {
  final languageCodeBytes = Uint8List.fromList(languageCode.codeUnits);
  final textBytes = Uint8List.fromList(text.codeUnits);

  final payload = Uint8List(1 + languageCodeBytes.length + textBytes.length);
  payload[0] = languageCodeBytes.length;
  payload.setRange(1, 1 + languageCodeBytes.length, languageCodeBytes);
  payload.setRange(1 + languageCodeBytes.length, payload.length, textBytes);

  return NdefRecord(
    typeNameFormat: TypeNameFormat.wellKnown,
    type: Uint8List.fromList([0x54]), // 'T' for text
    identifier: Uint8List(0),
    payload: payload,
  );
}

// Helper function to decode text from NDEF record
String? decodeTextRecord(NdefRecord record) {
  if (record.typeNameFormat != TypeNameFormat.wellKnown) return null;
  if (record.type.length != 1 || record.type[0] != 0x54) {
    return null; // Not a text record
  }

  final payload = record.payload;
  if (payload.isEmpty) return null;

  final languageCodeLength = payload[0] & 0x3f;
  if (payload.length < 1 + languageCodeLength) return null;

  return String.fromCharCodes(payload.skip(1 + languageCodeLength));
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
  NfcAvailability? _nfcAvailability;
  String _statusMessage = 'NFC állapot ellenőrzése...';

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final availability = await NfcManager.instance.checkAvailability();
    setState(() {
      _nfcAvailability = availability;
      _statusMessage = availability == NfcAvailability.unsupported
          ? 'NFC nem támogatott ezen az eszközön ✗'
          : availability == NfcAvailability.disabled
          ? 'NFC ki van kapcsolva - kapcsold be a beállításokban ✗'
          : 'NFC elérhető és működik ✓';
    });
  }

  bool get _isNfcReady => _nfcAvailability == NfcAvailability.enabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Tesztelő'), centerTitle: true),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _isNfcReady ? Colors.green.shade100 : Colors.red.shade100,
            child: Column(
              children: [
                Icon(
                  _isNfcReady ? Icons.check_circle : Icons.error,
                  size: 48,
                  color: _isNfcReady ? Colors.green : Colors.red,
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
          Expanded(
            child: _isNfcReady
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
                      _ModeCard(
                        title: 'Olvasó Mód',
                        subtitle: 'NFC címkék és adatok fogadása',
                        icon: Icons.nfc,
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NFCReaderPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'Író Mód',
                        subtitle: 'Adat írása NFC címkére',
                        icon: Icons.edit,
                        color: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NFCWriterPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'Peer-to-Peer Mód',
                        subtitle: 'Két telefon közötti adatcsere',
                        icon: Icons.swap_horiz,
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NFCP2PPage(),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, size: 64, color: Colors.orange),
                        SizedBox(height: 20),
                        Text(
                          'Az NFC nem használható',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 10),
                        Text(
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
                  color: color.withValues(alpha: 0.1),
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

class NFCReaderPage extends StatefulWidget {
  const NFCReaderPage({super.key});

  @override
  State<NFCReaderPage> createState() => _NFCReaderPageState();
}

class _NFCReaderPageState extends State<NFCReaderPage> {
  String _status = 'Várakozás...';
  final List<String> _dataLog = [];
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
      _dataLog.add('[${_timestamp()}] Olvasó mód elindítva');
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _status = 'NFC címke detektálva!';
          _dataLog.add('[${_timestamp()}] NFC címke észlelve');
        });

        final ndef = Ndef.from(tag);
        if (ndef != null) {
          setState(() {
            _dataLog.add('Típus: NDEF címke');
            _dataLog.add('Írható: ${ndef.isWritable ? "Igen" : "Nem"}');
            _dataLog.add('Kapacitás: ${ndef.maxSize} bájt');
          });

          final message = ndef.cachedMessage;
          if (message != null) {
            for (int i = 0; i < message.records.length; i++) {
              final record = message.records[i];
              setState(() {
                _dataLog.add('--- Rekord ${i + 1} ---');
                _dataLog.add('TNF: ${record.typeNameFormat.toString()}');
              });

              final text = decodeTextRecord(record);
              if (text != null) {
                setState(() {
                  _dataLog.add('Szöveg: $text');
                  _status = 'Beolvasva: $text';
                });
              }
            }
          }
        }

        // Tag detected - no need to access protected data
        setState(() {
          _dataLog.add('Tag észlelve és feldolgozva');
        });

        setState(() {
          _dataLog.add('[${_timestamp()}] Olvasás befejezve\n');
        });
      },
    );
  }

  void _stopReading() {
    NfcManager.instance.stopSession();
    setState(() {
      _isReading = false;
      _status = 'Olvasás leállítva';
      _dataLog.add('[${_timestamp()}] Olvasó mód leállítva\n');
    });
  }

  String _timestamp() => DateTime.now().toString().substring(11, 19);

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
                  onPressed: () => setState(() => _dataLog.clear()),
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
      setState(() => _status = 'Kérlek írj be egy üzenetet!');
      return;
    }

    setState(() {
      _isWriting = true;
      _status = 'Várakozás NFC címkére...';
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              setState(() {
                _status = 'Ez nem NDEF címke!';
                _isWriting = false;
              });
              await NfcManager.instance.stopSession();
              return;
            }

            if (!ndef.isWritable) {
              setState(() {
                _status = 'Ez a címke nem írható!';
                _isWriting = false;
              });
              await NfcManager.instance.stopSession();
              return;
            }

            final ndefMessage = NdefMessage(
              records: [createTextRecord(_textController.text)],
            );

            await ndef.write(message: ndefMessage);

            setState(() {
              _status = 'Sikeresen írva: "${_textController.text}"';
              _isWriting = false;
            });

            await NfcManager.instance.stopSession();
          } catch (e) {
            setState(() {
              _status = 'Hiba írás közben: $e';
              _isWriting = false;
            });
            await NfcManager.instance.stopSession();
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
  final List<String> _log = [];
  bool _isActive = false;

  void _startSender() async {
    if (_messageController.text.isEmpty) {
      setState(() => _status = 'Adj meg egy üzenetet!');
      return;
    }

    setState(() {
      _isActive = true;
      _status = 'Küldő mód: Érintsd a másik telefonhoz...';
      _log.add('[${_timestamp()}] Küldő mód aktiválva');
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            setState(() {
              _log.add('[${_timestamp()}] Eszköz detektálva');
            });

            final ndef = Ndef.from(tag);
            if (ndef != null && ndef.isWritable) {
              final ndefMessage = NdefMessage(
                records: [createTextRecord(_messageController.text)],
              );

              await ndef.write(message: ndefMessage);

              setState(() {
                _status = 'Üzenet sikeresen elküldve!';
                _log.add(
                  '[${_timestamp()}] Üzenet elküldve: "${_messageController.text}"',
                );
                _isActive = false;
              });

              await NfcManager.instance.stopSession();
            } else {
              setState(() {
                _status = 'Nem sikerült írni az eszközre';
                _log.add('[${_timestamp()}] Írási hiba - eszköz nem írható');
                _isActive = false;
              });
              await NfcManager.instance.stopSession();
            }
          } catch (e) {
            setState(() {
              _status = 'Hiba: $e';
              _log.add('[${_timestamp()}] Hiba: $e');
              _isActive = false;
            });
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Hiba: $e';
        _log.add('[${_timestamp()}] Hiba: $e');
        _isActive = false;
      });
    }
  }

  void _startReceiver() {
    setState(() {
      _isActive = true;
      _status = 'Fogadó mód: Érintsd a másik telefonhoz...';
      _log.add('[${_timestamp()}] Fogadó mód aktiválva');
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _log.add('[${_timestamp()}] Eszköz detektálva');
        });

        final ndef = Ndef.from(tag);
        if (ndef != null && ndef.cachedMessage != null) {
          for (var record in ndef.cachedMessage!.records) {
            final text = decodeTextRecord(record);
            if (text != null) {
              setState(() {
                _status = 'Üzenet fogadva!';
                _log.add('[${_timestamp()}] Fogadott üzenet: "$text"');
              });
            }
          }
        } else {
          setState(() {
            _log.add('[${_timestamp()}] Nincs NDEF adat');
          });
        }

        setState(() => _isActive = false);
        await NfcManager.instance.stopSession();
      },
    );
  }

  void _stop() {
    NfcManager.instance.stopSession();
    setState(() {
      _isActive = false;
      _status = 'Leállítva';
      _log.add('[${_timestamp()}] Mód leállítva\n');
    });
  }

  String _timestamp() => DateTime.now().toString().substring(11, 19);

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
                      onPressed: () => setState(() => _log.clear()),
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
