// /// Filter options for assignments and quizzes
// class FilterOptions {
//   final List<String>? groupIds;
//   final List<String>? statuses;
//   final DateTime? startDate;
//   final DateTime? endDate;
//   final String? searchQuery;

//   const FilterOptions({
//     this.groupIds,
//     this.statuses,
//     this.startDate,
//     this.endDate,
//     this.searchQuery,
//   });

//   FilterOptions copyWith({
//     List<String>? groupIds,
//     List<String>? statuses,
//     DateTime? startDate,
//     DateTime? endDate,
//     String? searchQuery,
//   }) {
//     return FilterOptions(
//       groupIds: groupIds ?? this.groupIds,
//       statuses: statuses ?? this.statuses,
//       startDate: startDate ?? this.startDate,
//       endDate: endDate ?? this.endDate,
//       searchQuery: searchQuery ?? this.searchQuery,
//     );
//   }

//   bool get hasFilters {
//     return (groupIds != null && groupIds!.isNotEmpty) ||
//         (statuses != null && statuses!.isNotEmpty) ||
//         startDate != null ||
//         endDate != null ||
//         (searchQuery != null && searchQuery!.isNotEmpty);
//   }

//   void clear() {
//     // Note: This creates a new empty instance
//   }

//   static FilterOptions get empty => const FilterOptions();
// }

// /// Sort options for lists
// enum SortField {
//   name,
//   deadline,
//   score,
//   date,
//   status,
// }

// enum SortOrder {
//   ascending,
//   descending,
// }

// class SortOptions {
//   final SortField field;
//   final SortOrder order;

//   const SortOptions({
//     required this.field,
//     required this.order,
//   });

//   SortOptions copyWith({
//     SortField? field,
//     SortOrder? order,
//   }) {
//     return SortOptions(
//       field: field ?? this.field,
//       order: order ?? this.order,
//     );
//   }

//   SortOptions toggleOrder() {
//     return SortOptions(
//       field: field,
//       order: order == SortOrder.ascending
//           ? SortOrder.descending
//           : SortOrder.ascending,
//     );
//   }

//   static const SortOptions defaultSort = SortOptions(
//     field: SortField.deadline,
//     order: SortOrder.ascending,
//   );
// }
