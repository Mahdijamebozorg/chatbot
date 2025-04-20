import 'dart:async';
import 'package:chatbot/chat_inputs.dart';
import 'package:chatbot/models/message.dart';
import 'package:chatbot/models/response.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Scroll controller for auto-scroll
  final List<Message> _messages = [];
  bool _isTyping = false; // Flag to track if AI is typing
  String? _currentFollowUp; // Track the current follow-up question

  AnimationController get messageAnimation {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void initState() {
    _messages.add(
      Message(
        text: 'سلام! چطور می‌توانم به شما کمک کنم؟',
        isUser: false,
        animation: messageAnimation,
        buttons: [
          'اضافه کردن خوردو',
          'شارژ کیف پول',
          'رزرو طرح ترافیک',
          'پرداخت خودکار بدهی',
        ],
      )..animation.forward(),
    );
    _simulateTypingEffect(
      _messages.first,
      _messages.first.text,
      _messages.first.buttons,
    );
    super.initState();
  }

  final List<Response> _responses = [
    Response(
      triggers: ['انصراف'],
      text: 'چطور می‌توانم به شما کمک کنم؟',
      buttons: [
        'اضافه کردن خوردو',
        'شارژ کیف پول',
        'رزرو طرح ترافیک',
        'پرداخت خودکار بدهی',
      ],
    ),
    Response(
      triggers: ['اضافه', 'افزودن', 'پلاک', 'شاسی'],
      text: 'ماشین با مشخصات وارد شده اضافه شد',
      buttons: ['انصراف'],
      followUp: 'لطفاً شماره پلاک خودرو را وارد کنید.',
    ),
    Response(
      triggers: ['شارژ', 'کیف', 'پول', 'اعتبار'],
      text: 'برای شارژ کیف پول به درگاه بانکی منتقل می‌شوید',
      buttons: ['انصراف'],
      followUp: 'چه مبلغی را می‌خواهید شارژ کنید؟',
    ),
    Response(
      triggers: ['رزرو', 'طرح', 'ترافیک'],
      text: 'طرح ترافیک برای شما رزرو شد',
      buttons: ['انصراف'],
      followUp: 'لطفاً تاریخ رزرو را وارد کنید.',
    ),
    Response(
      triggers: ['بدهی', 'خودکار'],
      text: 'درخواست فعال سازی پرداخت خودکار انجام شد',
      buttons: ['انصراف'],
      followUp: 'لطفاً شماره حساب خود را وارد کنید.',
    ),
  ];

  void _sendMessage(String messageText, {bool isBot = false}) {
    if (messageText.trim().isEmpty || _isTyping) {
      return;
    }

    if (!isBot) {
      final userMessage = Message(
        text: messageText,
        isUser: true,
        animation: messageAnimation,
      );
      setState(() {
        _messages.add(userMessage);
        _controller.clear();
        userMessage.animation.forward().then((value) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        _isTyping = true;
      });
    }

    Future.delayed(Duration(seconds: isBot ? 0 : 1), () {
      Response response;

      if (isBot) {
        response = Response(triggers: [], text: messageText, buttons: []);
        _currentFollowUp = null;
      } else if (_currentFollowUp != null) {
        // Handle specific follow-up responses
        if (_currentFollowUp == 'لطفاً شماره پلاک خودرو را وارد کنید.') {
          response = Response(
            triggers: [],
            text: 'شماره پلاک خودرو با موفقیت ثبت شد: $messageText',
            buttons: [],
          );
        } else if (_currentFollowUp == 'چه مبلغی را می‌خواهید شارژ کنید؟') {
          response = Response(
            triggers: [],
            text: 'مبلغ $messageText درحال اتصال به درگاه پرداخت ...',
            buttons: ['انصراف'],
          );
        } else if (_currentFollowUp == 'لطفاً تاریخ رزرو را وارد کنید.') {
          response = Response(
            triggers: [],
            text: 'تاریخ رزرو شما ثبت شد: $messageText',
            buttons: [],
          );
        } else if (_currentFollowUp == 'لطفاً شماره حساب خود را وارد کنید.') {
          response = Response(
            triggers: [],
            text: 'شماره حساب شما ثبت شد: $messageText',
            buttons: [],
          );
        } else {
          response = Response(
            triggers: [],
            text: 'اطلاعات شما ثبت شد: $messageText',
            buttons: [],
          );
        }
        _currentFollowUp = null; // Reset follow-up state
      } else {
        // Find the appropriate response
        response = _responses.firstWhere(
          (response) =>
              response.triggers.any((trigger) => messageText.contains(trigger)),
          orElse:
              () => Response(
                triggers: [],
                text: 'متأسفم، متوجه نشدم. لطفاً دوباره تلاش کنید.',
                buttons: [
                  'اضافه کردن خوردو',
                  'شارژ کیف پول',
                  'رزرو طرح ترافیک',
                  'پرداخت خودکار بدهی',
                ],
              ),
        );

        // Set follow-up question if available
        if (response.followUp != null) {
          _currentFollowUp = response.followUp;
        }
      }

      final botMessage = Message(
        text: '',
        isUser: false,
        animation: messageAnimation,
      );

      setState(() {
        _messages.add(botMessage);
      });

      botMessage.animation.forward();

      _simulateTypingEffect(
        botMessage,
        _currentFollowUp ??
            response.text, // Show follow-up question if available
        response.buttons,
      );
    });
  }

  void _simulateTypingEffect(
    Message message,
    String fullText, [
    List<String>? buttons,
  ]) {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < fullText.length) {
        setState(() {
          message.text = fullText.substring(0, index + 1);
        });
        index++;
        _scrollToBottom(); // Auto-scroll as the text grows
      } else {
        timer.cancel();
        // Add buttons after the typing effect is complete
        if (buttons != null || buttons!.isEmpty) {
          setState(() {
            message.buttons = buttons;
            _scrollToBottom();
          });
        }
        setState(() {
          _isTyping = false; // Reset typing flag
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    for (var message in _messages) {
      message.animation.dispose();
    }
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'چت بات هوشمند شهرداری تهران',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController, // Attach the scroll controller
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return FadeTransition(
                      opacity: message.animation,
                      child: MessageBubble(
                        text: message.text,
                        isUser: message.isUser,
                        buttons: message.buttons,
                        onButtonPressed: (buttonText) {
                          _currentFollowUp = null;
                          _sendMessage(buttonText);
                        },
                      ),
                    );
                  },
                ),
              ),
              ChatInputs(
                triggerWait: (val) {
                  setState(() {
                    _isTyping = val;
                  });
                },
                typing: _isTyping,
                sendMessage: _sendMessage,
                textCtrl: _controller,
                uploadQrCode: (String code) {
                  _sendMessage('کد QR آپلود شد: $code', isBot: true);
                },
                uploadLocation: (double x, double y) {
                  _sendMessage('موقعیت مکانی آپلود شد: ($x, $y)', isBot: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
