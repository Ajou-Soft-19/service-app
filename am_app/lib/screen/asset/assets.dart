import 'package:flutter/material.dart';

class Assets {
  void showPopup(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPopupWithCallback(
      BuildContext context, String text, Function callback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  child: Text(
                    text,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      callback();
                    },
                    child: const Text(
                      '권한 설정하기',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showErrorSnackBar(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
                child:
                    Text(message!.replaceFirst("Exception: ", ""))), // 여기를 수정
          ],
        ),
        backgroundColor: Colors.red[200],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void showSnackBar(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.task_alt, color: Colors.blue),
            const SizedBox(width: 8),
            Flexible(child: Text(message ?? "")), // 여기를 수정
          ],
        ),
        backgroundColor: Colors.blue[200],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void showLoadingDialog(BuildContext context, String? message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message ?? ""),
              ],
            ),
          ),
        );
      },
    );
  }

  void showWhereEmergency(BuildContext context, Alignment alignment, String direction) {
    OverlayEntry overlayEntry = OverlayEntry(builder: (context) => Stack(
      children: [
        Align(
          alignment: alignment,
          child: IgnorePointer(
            ignoring: true,
            child: Icon(
              Icons.warning,
              size: 50,
              color: Colors.red
            )
          )
        ),

        Positioned(
          bottom: 20.0,
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              alignment: Alignment.center,
              width:MediaQuery.of(context).size.width,
              child: Text(
                'Emergency Car From the $direction\nSlow Down and Move Aside!',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.bold
                ),
              )
            )
          )
        )
      ],
    ));
    Overlay.of(context)!.insert(overlayEntry);

    // 5초 후에 위젯 제거
    Future.delayed(Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }
}
