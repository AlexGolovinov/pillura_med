import 'package:flutter/material.dart';

import '../../domain/enums/meal_relation.dart';
import 'custom_card.dart';

class MealRelationWidget extends StatefulWidget {
  final void Function(MealRelation?)? onSaved;
  const MealRelationWidget({super.key, this.onSaved});

  @override
  State<MealRelationWidget> createState() => _MealRelationWidgetState();
}

class _MealRelationWidgetState extends State<MealRelationWidget> {
  final List<MealRelation> _mealRelations = MealRelation.values;
  @override
  Widget build(BuildContext context) {
    return FormField<MealRelation?>(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null) {
          return 'Выберите прием таблеток относительно еды';
        }
        return null;
      },
      onSaved: widget.onSaved,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Принимать лекарство",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mealRelations
                  .map(
                    (e) => GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        state.didChange(e);
                      },
                      child: customCard(
                        title: e.label,
                        isSelected: state.value == e,
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
