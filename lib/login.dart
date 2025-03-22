import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'common.dart';
import 'prompt.dart';

const String signupURL =
    "https://rw4mikh1ia.execute-api.us-west-2.amazonaws.com/v1/signup";
const String loginURL =
    "https://rw4mikh1ia.execute-api.us-west-2.amazonaws.com/v1/login";

class LoginSignupPage extends StatefulWidget {
  final bool isSignup;
  final String? topMessage;

  const LoginSignupPage({super.key, this.isSignup = false, this.topMessage});

  @override
  State<StatefulWidget> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white54,
                    backgroundImage: AssetImage("images/logo.png"),
                  ),
                  const SizedBox(height: 20),
                  if (widget.topMessage != null) ...[
                    Text(
                      widget.topMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      labelText: "ID",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fillColor: Colors.white.withAlpha(60),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fillColor: Colors.white.withAlpha(60),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      String userId = _userIdController.text.trim();
                      String password = _passwordController.text.trim();
                      Widget destination = PromptInputPage();
                      var uri =
                          widget.isSignup
                              ? Uri.parse(signupURL)
                              : Uri.parse(loginURL);
                      final headers = {'Content-Type': 'application/json'};
                      try {
                        final body = jsonEncode({
                          "user_id": userId,
                          "password": password,
                        });
                        final res = await http.post(
                          uri,
                          headers: headers,
                          body: body,
                        );
                        if (200 <= res.statusCode && res.statusCode < 300) {
                          String errorString =
                              widget.isSignup
                                  ? "既に登録されています"
                                  : "ユーザー名またはパスワードがちがいます";
                          destination = LoginSignupPage(
                            topMessage: errorString,
                          );
                        }
                        debugPrint("statusCode: ${res.statusCode}");
                        debugPrint("responseBody: ${res.body}");
                      } catch (e) {
                        debugPrint("[LOGIN ERROR] $e");
                        destination = LoginSignupPage(
                          topMessage: "ログイン処理に問題が発生しました: $e",
                        ); // TODO: Remove $e
                      }
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => destination),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      child:
                          widget.isSignup ? Text("サインアップして開始") : Text("ログイン"),
                    ),
                  ),
                  if (!widget.isSignup) ...[
                    const SizedBox(height: 10),
                    Text("はじめて使いますか？"),
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => LoginSignupPage(isSignup: true),
                            ),
                          ),
                      child: Text(
                        "サインアップ",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
