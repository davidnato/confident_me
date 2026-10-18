import 'package:flutter/material.dart';

IconData achievementIcon(String key) {
  switch (key) {
    case 'flag':
      return Icons.flag_rounded;
    case 'steps':
      return Icons.directions_walk_rounded;
    case 'trail':
      return Icons.route_rounded;
    case 'explore':
      return Icons.explore_rounded;
    case 'category':
      return Icons.category_rounded;
    case 'stretch':
      return Icons.trending_up_rounded;
    case 'summit':
      return Icons.landscape_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    case 'edit':
      return Icons.edit_note_rounded;
    case 'calendar':
      return Icons.event_available_rounded;
    case 'week':
      return Icons.date_range_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'practice':
      return Icons.self_improvement_rounded;
    case 'breath':
      return Icons.air_rounded;
    case 'chat':
      return Icons.forum_rounded;
    case 'journal':
      return Icons.menu_book_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}
