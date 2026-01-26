import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildSectionsShimmerGrid(BuildContext context) {
  final theme = Theme.of(context);
  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.8,
    ),
    itemCount: 6,
    itemBuilder: (context, index) {
      return Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        highlightColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildItemsShimmerGrid(BuildContext context) {
  final theme = Theme.of(context);
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10.0,
      mainAxisSpacing: 10.0,
    ),
    itemCount: 8,
    itemBuilder: (context, index) {
      return Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        highlightColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
