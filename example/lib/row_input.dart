import 'package:flutter/material.dart';

class RowFunction extends StatefulWidget {
  const RowFunction(
      {Key? key, required this.onPress, this.text = '', this.placeholder = ''})
      : super(key: key);

  final ValueSetter<String> onPress;
  final String text;
  final String placeholder;

  @override
  _RowFunctionState createState() => _RowFunctionState();
}

class _RowFunctionState extends State<RowFunction> {
  final _controller = TextEditingController(text: '10000');
  String amount = '0';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26.0),
              ),
              hintText: widget.placeholder,
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
            child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 110,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.blue),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ))),
                    onPressed: () {
                      widget.onPress(_controller.text);
                    },
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
