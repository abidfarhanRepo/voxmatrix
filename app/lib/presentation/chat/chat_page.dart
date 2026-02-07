import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/constants/app_strings.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_bloc.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_state.dart';
import 'package:voxmatrix/presentation/chat/bloc/chat_bloc.dart';
import 'package:voxmatrix/presentation/chat/bloc/chat_event.dart';
import 'package:voxmatrix/presentation/chat/bloc/chat_state.dart';
import 'package:voxmatrix/presentation/chat/widgets/message_bubble.dart';
import 'package:voxmatrix/presentation/chat/widgets/voice_recorder_widget.dart';
import 'package:voxmatrix/presentation/crypto/bloc/crypto_bloc.dart';
import 'package:voxmatrix/presentation/crypto/bloc/crypto_event.dart';
import 'package:voxmatrix/presentation/crypto/bloc/crypto_state.dart';
import 'package:voxmatrix/presentation/crypto/widgets/encryption_indicator.dart';
import 'package:voxmatrix/presentation/call/bloc/call_bloc.dart';
import 'package:voxmatrix/presentation/call/bloc/call_event.dart';
import 'package:voxmatrix/presentation/widgets/loading_widget.dart';
import 'package:voxmatrix/core/widgets/app_widgets.dart';
import 'package:voxmatrix/presentation/widgets/glass_app_bar.dart';
import 'package:voxmatrix/presentation/widgets/glass_container.dart';
import 'package:voxmatrix/presentation/widgets/glass_scaffold.dart';

/// Chat/conversation page for a single room
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.roomId,
    required this.roomName,
    this.isDirect = false,
  });

  final String roomId;
  final String roomName;
  final bool isDirect;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isTyping = false;
  MessageEntity? _replyingToMessage;
  MessageEntity? _editingMessage;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadMessages(roomId: widget.roomId));
    context.read<ChatBloc>().add(SubscribeToMessages(widget.roomId));
    context.read<CryptoBloc>().add(const InitializeCrypto());
    context.read<CryptoBloc>().add(GetRoomCryptoInfo(widget.roomId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatFileUploaded) {
          final fileName = state.mxcUri.split('/').last;
          context.read<ChatBloc>().add(SendMediaMessage(
            roomId: widget.roomId,
            content: '',
            attachments: [
              Attachment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: AttachmentType.image,
                url: state.mxcUri,
                name: fileName,
                mimeType: 'image/jpeg',
              ),
            ],
          ));
        } else if (state is ChatMessageEdited) {
          setState(() {
            _editingMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message edited')),
          );
        } else if (state is ChatMessageDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message deleted')),
          );
        } else if (state is ChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return GlassScaffold(
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildMessagesList(context),
                ),
                _buildTypingIndicator(context),
                _buildMessageInput(context),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return GlassAppBar(
      title: BlocBuilder<CryptoBloc, CryptoState>(
        buildWhen: (previous, current) => current is CryptoRoomInfoLoaded,
        builder: (context, cryptoState) {
          RoomEncryptionState encryptionState = RoomEncryptionState.unknown;

          if (cryptoState is CryptoRoomInfoLoaded &&
              cryptoState.roomId == widget.roomId) {
            encryptionState = cryptoState.info.encryptionState;
          } else if (cryptoState is! CryptoRoomInfoLoaded) {
            encryptionState = RoomEncryptionState.encrypted;
          }

          return Row(
            children: [
              Hero(
                tag: 'avatar_${widget.roomId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    widget.roomName.isNotEmpty ? widget.roomName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.roomName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        EncryptionIndicator(
                          state: encryptionState,
                          iconSize: 12,
                        ),
                      ],
                    ),
                    Text(
                      widget.isDirect ? 'Active Now' : 'Room',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        if (widget.isDirect) ...[
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => _startCall(context, isVideoCall: false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () => _startCall(context, isVideoCall: true),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textPrimary),
          onPressed: () => _showRoomOptions(context),
        ),
      ],
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded || state is ChatMessageSent) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state is ChatLoading) {
          return const LoadingWidget();
        } else if (state is ChatLoaded) {
          final messages = state.messages;

          if (messages.isEmpty) {
            return _buildEmptyState(context);
          }

          final authState = context.read<AuthBloc>().state;
          final currentUserId =
              authState is AuthAuthenticated ? authState.user.id : null;

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppConstants.spacing),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final previousMessage = index > 0 ? messages[index - 1] : null;
              final isCurrentUser =
                  currentUserId != null && message.senderId == currentUserId;

              if (previousMessage != null &&
                  !_isSameDay(message.timestamp, previousMessage.timestamp)) {
                return Column(
                  children: [
                    _buildDateDivider(context, message.timestamp),
                    MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      previousMessage: previousMessage,
                      onLongPress: () => _showMessageActions(context, message),
                    ),
                  ],
                );
              }

              return MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                previousMessage: previousMessage,
                onLongPress: () => _showMessageActions(context, message),
              );
            },
          );
        } else if (state is ChatError) {
          return _buildErrorState(context, state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDateDivider(BuildContext context, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing),
      child: Center(
        child: GlassContainer(
          opacity: 0.1,
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            _formatDate(timestamp),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: 24,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isDirect ? Icons.chat_bubble_outline : Icons.group,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: 24,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing * 2),
            FilledButton.icon(
              onPressed: () {
                context
                    .read<ChatBloc>()
                    .add(LoadMessages(roomId: widget.roomId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.errorRetry),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (previous, current) => current is ChatTypingUsersUpdated,
      builder: (context, state) {
        if (state is ChatTypingUsersUpdated && state.userIds.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing,
              vertical: 8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.userIds.length == 1
                      ? 'Someone is typing...'
                      : '${state.userIds.length} people are typing...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: const Border(top: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 24,
                      opacity: 0.08,
                      blur: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_rounded, color: Color(0x80FFFFFF), size: 24),
                            onPressed: () => _showAttachmentOptions(context),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(color: Color(0x66FFFFFF), fontSize: 15),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                fillColor: Colors.transparent,
                              ),
                              maxLines: 5,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                final isTyping = value.isNotEmpty;
                                if (_isTyping != isTyping) {
                                  setState(() => _isTyping = isTyping);
                                  context.read<ChatBloc>().add(SendTypingNotification(roomId: widget.roomId, isTyping: isTyping));
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic_rounded, color: Color(0x80FFFFFF), size: 22),
                            onPressed: () => _showVoiceRecorder(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        _sendMessage(context, _messageController.text.trim());
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFB30000), Color(0xFF4A0404)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: 12,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _replyingToMessage!.senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _replyingToMessage!.content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: () {
                setState(() {
                  _replyingToMessage = null;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPreview(BuildContext context) {
    if (_editingMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        opacity: 0.1,
        color: Colors.orange.withOpacity(0.2),
        borderRadius: 12,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.edit, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Editing message...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: () {
                setState(() {
                  _editingMessage = null;
                  _messageController.clear();
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildSendButton(BuildContext context) {
    final canSend = _messageController.text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: canSend ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          canSend ? Icons.arrow_upward : Icons.mic, 
          size: 20,
          color: canSend ? AppColors.onPrimary : AppColors.textSecondary,
        ),
        onPressed: canSend
            ? () => _sendMessage(context, _messageController.text.trim())
            : () {
                _showVoiceRecorder(context);
              },
        tooltip: canSend ? AppStrings.sendMessage : AppStrings.voiceMessage,
      ),
    );
  }

  void _sendMessage(BuildContext context, String content) {
    if (_editingMessage != null) {
      context.read<ChatBloc>().add(
            EditMessage(
              roomId: widget.roomId,
              messageId: _editingMessage!.id,
              newContent: content,
            ),
          );
    } else {
      context.read<ChatBloc>().add(
            SendMessage(
              roomId: widget.roomId,
              content: content,
              replyToId: _replyingToMessage?.id,
            ),
          );
    }

    _messageController.clear();
    _focusNode.requestFocus();

    setState(() {
      _isTyping = false;
      _replyingToMessage = null;
      _editingMessage = null;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<ChatBloc>().add(
              SendTypingNotification(
                roomId: widget.roomId,
                isTyping: false,
              ),
            );
      }
    });
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        opacity: 0.1,
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Gallery', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Camera', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: AppColors.primary),
                title: const Text('File', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic, color: AppColors.primary),
                title: const Text('Voice Message', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showVoiceRecorder(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Location', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _shareLocation(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: const Text('Contact', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _shareContact(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context, MessageEntity message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        opacity: 0.1,
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.textPrimary),
                title: const Text('Reply', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingToMessage = message;
                  });
                  _focusNode.requestFocus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined, color: AppColors.textPrimary),
                title: const Text('React', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(context, message);
                },
              ),
              if (message.senderId == widget.roomId) 
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.textPrimary),
                  title: const Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessage = message;
                      _messageController.text = message.content;
                    });
                    _focusNode.requestFocus();
                  },
                ),
              if (message.senderId == widget.roomId) 
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ChatBloc>().add(DeleteMessage(
                      roomId: widget.roomId,
                      messageId: message.id,
                    ));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.textPrimary),
                title: const Text('Copy', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, MessageEntity message) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🎉'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        opacity: 0.1,
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('React with an emoji', style: TextStyle(color: AppColors.textPrimary)),
              ),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 1,
                ),
                itemCount: reactions.length,
                itemBuilder: (context, index) {
                  final emoji = reactions[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.read<ChatBloc>().add(AddReaction(
                        roomId: widget.roomId,
                        messageId: message.id,
                        emoji: emoji,
                      ));
                    },
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission denied')),
      );
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      _handlePickedImage(image.path);
    }
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      _handlePickedImage(image.path);
    }
  }

  void _handlePickedImage(String imagePath) {
    context.read<ChatBloc>().add(UploadFile(
      roomId: widget.roomId,
      filePath: imagePath,
    ));
  }

  Future<void> _pickFile() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null && mounted) {
        _handlePickedFile(result.files.single.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  void _handlePickedFile(String filePath) {
    context.read<ChatBloc>().add(UploadFile(
      roomId: widget.roomId,
      filePath: filePath,
    ));
  }

  void _showVoiceRecorder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recording coming soon!')),
    );
  }

  void _showRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        opacity: 0.1,
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: AppColors.textPrimary),
                title: const Text('Room info', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show room info
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: AppColors.textPrimary),
                title: const Text('Search messages', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageSearch(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: AppColors.textPrimary),
                title: const Text('Notification settings', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show notification settings
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  void _showMessageSearch(BuildContext context) {
    final chatState = context.read<ChatBloc>().state;
    final messages = chatState is ChatLoaded ? (chatState as ChatLoaded).messages : <MessageEntity>[];

    showDialog(
      context: context,
      builder: (context) => _MessageSearchDialog(messages: messages),
    );
  }

  Future<void> _shareLocation(BuildContext context) async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationContent = {
        'type': 'm.location',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };

      context.read<ChatBloc>().add(SendMessage(
        roomId: widget.roomId,
        content: '📍 Location: ${position.latitude}, ${position.longitude}',
        messageType: 'm.location',
        contentData: locationContent,
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location shared')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _shareContact(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;

    final contactContent = {
      'type': 'm.contact',
      'userId': user.id,
      'displayName': user.displayName,
    };

    context.read<ChatBloc>().add(SendMessage(
      roomId: widget.roomId,
      content: '👤 ${user.displayName}',
      messageType: 'm.contact',
      contentData: contactContent,
    ));

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} shared as contact')),
      );
    }
  }

  void _startCall(BuildContext context, {required bool isVideoCall}) {
    context.read<CallBloc>().add(CreateCallEvent(
      roomId: widget.roomId,
      calleeId: '', 
      isVideoCall: isVideoCall,
    ));
    
    Navigator.pushNamed(
      context,
      '/call',
    );
  }

  void _copyMessage(MessageEntity message) async {
    await Clipboard.setData(ClipboardData(text: message.content));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _MessageSearchDialog extends StatefulWidget {
  const _MessageSearchDialog({
    required this.messages,
  });

  final List<MessageEntity> messages;

  @override
  State<_MessageSearchDialog> createState() => _MessageSearchDialogState();
}

class _MessageSearchDialogState extends State<_MessageSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<MessageEntity> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _filteredMessages = widget.messages;
  }

  void _filterMessages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = widget.messages;
      } else {
        _filteredMessages = widget.messages
            .where((msg) =>
                msg.content.toLowerCase().contains(query.toLowerCase()) ||
                msg.senderId.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface.withOpacity(0.9),
      title: const Text('Search Messages', style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
              ),
              onChanged: _filterMessages,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_filteredMessages.isEmpty)
              const Text('No messages found', style: TextStyle(color: AppColors.textSecondary))
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _filteredMessages[index];
                    return ListTile(
                      title: Text(msg.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(msg.timestamp)} • ${msg.senderId}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}