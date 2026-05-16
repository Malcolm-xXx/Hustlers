class ChatModel {
  final String id;
  final String buyerName;
  final String buyerAvatarUrl;
  final String orderNumber;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isResolved;
  final int itemCount;
  final double orderTotal;

  const ChatModel({
    required this.id,
    required this.buyerName,
    this.buyerAvatarUrl = '',
    required this.orderNumber,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isResolved = false,
    this.itemCount = 0,
    this.orderTotal = 0,
  });

  ChatModel copyWith({
    int? unreadCount,
    bool? isResolved,
    String? lastMessage,
    String? time,
  }) {
    return ChatModel(
      id: id,
      buyerName: buyerName,
      buyerAvatarUrl: buyerAvatarUrl,
      orderNumber: orderNumber,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline,
      isResolved: isResolved ?? this.isResolved,
      itemCount: itemCount,
      orderTotal: orderTotal,
    );
  }

  static final List<ChatModel> mockActiveChats = [
    const ChatModel(
      id: 'c1',
      buyerName: 'Chinedu James',
      orderNumber: '#1204',
      lastMessage: "I've seen the big tomatoes. Shoul...",
      time: '14:30',
      unreadCount: 2,
      isOnline: true,
      itemCount: 5,
      orderTotal: 4500,
    ),
    const ChatModel(
      id: 'c2',
      buyerName: 'Tunde Bola',
      orderNumber: '#1245',
      lastMessage: "I'm in the queue now, it's a bit long.",
      time: '14:30',
      unreadCount: 1,
      isOnline: true,
      itemCount: 3,
      orderTotal: 2800,
    ),
    const ChatModel(
      id: 'c3',
      buyerName: 'Seyi Isaac',
      orderNumber: '#1510',
      lastMessage: 'It seems this type is unavailable',
      time: '14:30',
      unreadCount: 1,
      isOnline: true,
      itemCount: 4,
      orderTotal: 3200,
    ),
    const ChatModel(
      id: 'c4',
      buyerName: 'Amina Umar',
      orderNumber: '#1510',
      lastMessage: 'The store is closed. Can I get it els...',
      time: '14:30',
      unreadCount: 1,
      isOnline: true,
      itemCount: 2,
      orderTotal: 1500,
    ),
  ];

  static final List<ChatModel> mockResolvedChats = [
    const ChatModel(
      id: 'r1',
      buyerName: 'Chinedu James',
      orderNumber: '#1204',
      lastMessage: 'Delivered! Thanks for the tip',
      time: '',
      isResolved: true,
      itemCount: 5,
      orderTotal: 4500,
    ),
    const ChatModel(
      id: 'r2',
      buyerName: 'Tunde Bola',
      orderNumber: '#1245',
      lastMessage: 'The cylinder is at your doorstep n...',
      time: '',
      isResolved: true,
      itemCount: 3,
      orderTotal: 2800,
    ),
  ];
}

class MessageModel {
  final String id;
  final String text;
  final String time;
  final bool isMe;
  final String? senderName;

  const MessageModel({
    required this.id,
    required this.text,
    required this.time,
    required this.isMe,
    this.senderName,
  });

  static final List<MessageModel> mockConversation = [
    const MessageModel(
      id: 'm1',
      text: 'HI Rufus!',
      time: '14:30',
      isMe: false,
      senderName: 'Chinedu',
    ),
    const MessageModel(
      id: 'm2',
      text:
          'The pepper here is \u20A6500 per paint, but they look a bit dry. Should I proceed?',
      time: '14:30',
      isMe: false,
    ),
    const MessageModel(
      id: 'm3',
      text: 'Hi Chinedu!',
      time: '14:30',
      isMe: true,
    ),
    const MessageModel(
      id: 'm4',
      text:
          'No, please check the next stall. I prefer the fresh ones even if they are \u20A6600.',
      time: '14:30',
      isMe: true,
    ),
    const MessageModel(
      id: 'm5',
      text: 'Found them! These are much better. Picking them up now.',
      time: '14:30',
      isMe: false,
    ),
    const MessageModel(
      id: 'm6',
      text: 'Thank you so much, Chinedu',
      time: '14:30',
      isMe: true,
    ),
  ];

  static final List<String> recentSearches = [
    'Sarah Williams',
    'Michael Chen',
    'Order #1204',
    'Funke',
  ];

  static final List<ChatSearchSuggestion> suggestedChats = [
    const ChatSearchSuggestion(
      name: 'Sarah Williams',
      subtitle: 'Active chat \u2022 Order #1204',
    ),
    const ChatSearchSuggestion(
      name: 'Tunde Bola',
      subtitle: 'Resolved \u2022 Order #1245',
    ),
    const ChatSearchSuggestion(
      name: 'Funke Adeyemi',
      subtitle: 'Active chat \u2022 Order #1187',
    ),
  ];

  static final List<ChatSearchResult> mockSearchResults = [
    const ChatSearchResult(
      name: 'Tunde Bola',
      orderNumber: '#1275',
      message: 'The cylinder is at your doorstep now.',
      timeAgo: '2 days ago',
    ),
    const ChatSearchResult(
      name: 'Tunde Bola',
      orderNumber: '#1245',
      message: 'Nice one bro',
      timeAgo: '4 days ago',
    ),
    const ChatSearchResult(
      name: 'Tunde Bola',
      orderNumber: '#1213',
      message: 'Thank you so much! Received',
      timeAgo: '6 days ago',
    ),
    const ChatSearchResult(
      name: 'Tunde Bola',
      orderNumber: '#1205',
      message: 'Thanks for the update',
      timeAgo: '10 days ago',
    ),
    const ChatSearchResult(
      name: 'Tunde Bola',
      orderNumber: '#1190',
      message: 'Awesome. Until next time.',
      timeAgo: '20 days ago',
    ),
  ];
}

class ChatSearchSuggestion {
  final String name;
  final String subtitle;

  const ChatSearchSuggestion({
    required this.name,
    required this.subtitle,
  });
}

class ChatSearchResult {
  final String name;
  final String orderNumber;
  final String message;
  final String timeAgo;

  const ChatSearchResult({
    required this.name,
    required this.orderNumber,
    required this.message,
    required this.timeAgo,
  });
}
