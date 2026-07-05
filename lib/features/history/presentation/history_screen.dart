import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import '../../request/domain/medical_request.dart';
import '../../request/data/request_repository.dart';
import 'history_bloc.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryBloc(
        repository: context.read<RequestRepository>(),
      )..add(LoadHistory()),
      child: const HistoryView(),
    );
  }
}

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request History'),
        centerTitle: true,
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryEmpty) {
            return EmptyStateWidget(
              icon: Icons.history_outlined,
              title: 'No History Yet',
              subtitle: 'Your exported and submitted requests will appear here',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/request'),
                icon: const Icon(Icons.add),
                label: const Text('Create First Request'),
              ),
            );
          }
          if (state is HistoryLoaded) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '${state.requests.length} Requests',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      FilterChip(
                        label: const Text('All'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Draft'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.requests.length,
                    itemBuilder: (context, index) {
                      final request = state.requests[index];
                      return _RequestHistoryCard(request: request);
                    },
                  ),
                ),
              ],
            );
          }
          if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HistoryBloc>().add(LoadHistory()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RequestHistoryCard extends StatelessWidget {
  final MedicalRequest request;

  const _RequestHistoryCard({required this.request});

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'exported':
        return Colors.blue;
      case 'submitted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit_outlined;
      case 'exported':
        return Icons.file_download_outlined;
      case 'submitted':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'exported':
        return 'Exported';
      case 'submitted':
        return 'Submitted';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/request',
            arguments: request.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (request.title?.isEmpty ?? true) ? 'Untitled Request' : request.title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      _statusIcon(request.status),
                      size: 16,
                      color: _statusColor(request.status),
                    ),
                    label: Text(
                      _statusLabel(request.status),
                      style: TextStyle(
                        color: _statusColor(request.status),
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _statusColor(request.status).withValues(alpha: 0.1),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (request.department?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      request.department!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                  if (request.requester?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      request.requester!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/request',
                        arguments: request.id,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context, request),
                    icon: const Icon(Icons.delete_outlined, size: 18, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MedicalRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request?'),
        content: Text(
          'Are you sure you want to delete "${(request.title?.isEmpty ?? true) ? "Untitled Request" : request.title!}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HistoryBloc>().add(DeleteHistoryItem(request.id!));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
