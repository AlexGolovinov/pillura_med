enum MealRelation {
  beforeMeal, // до еды
  withMeal, // во время еды
  afterMeal, // после еды
  regardless, // независимо от еды
}

extension MealRelationLabel on MealRelation {
  String get label {
    switch (this) {
      case MealRelation.beforeMeal:
        return 'До еды';
      case MealRelation.withMeal:
        return 'Во время еды';
      case MealRelation.afterMeal:
        return 'После еды';
      case MealRelation.regardless:
        return 'Независимо от еды';
    }
  }
}
