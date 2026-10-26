import 'package:flutter/material.dart';
import '../../domain/lesson.dart';

class PuzzleCalc extends StatefulWidget {
  const PuzzleCalc({super.key, required this.question, required this.onAnswer});
  final Question question;
  final ValueChanged<Object> onAnswer;
  @override
  State<PuzzleCalc> createState() => _PuzzleCalcState();
}
class _PuzzleCalcState extends State<PuzzleCalc> {
  final TextEditingController _input = TextEditingController();
  String? _error;
  @override
  void dispose() { _input.dispose(); super.dispose(); }
  void _submit() {
    final double? value = double.tryParse(_input.text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0) {
      setState(() => _error = 'Zadaj kladnú dĺžku v metroch.'); return;
    }
    widget.onAnswer(value);
  }
  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
    Semantics(label: 'Pravouhlý trojuholník: základňa 3 metre, výška 4 metre, prepona je rebrík.', child: SizedBox(height: 220, width: 300, child: CustomPaint(painter: TrianglePainter(Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.onSurface)))),
    const Text('Pomôcka: a² + b² = c²'), const SizedBox(height: 16),
    TextField(controller: _input, keyboardType: const TextInputType.numberWithOptions(decimal: true), onSubmitted: (_) => _submit(), decoration: InputDecoration(labelText: 'Dĺžka rebríka', suffixText: 'm', errorText: _error, border: const OutlineInputBorder())),
    const SizedBox(height: 16), FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.shield), label: const Text('Zachrániť prieskumníka')),
  ]);
}
class TrianglePainter extends CustomPainter {
  TrianglePainter(this.color, this.textColor);
  final Color color, textColor;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()..color = color..strokeWidth = 5..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(50, 175)..lineTo(245,175)..lineTo(245,30)..close(), pen);
    canvas.drawPath(Path()..moveTo(225,175)..lineTo(225,155)..lineTo(245,155), Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=2);
    for (final (String, Offset) label in <(String, Offset)>[('3 m',const Offset(125,182)),('4 m',const Offset(250,90)),('c = ?',const Offset(100,65)),('★',const Offset(230,0))]) {
      final TextPainter text = TextPainter(text: TextSpan(text: label.$1, style: TextStyle(color: textColor, fontSize: 18)), textDirection: TextDirection.ltr)..layout();
      text.paint(canvas,label.$2);
    }
  }
  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => oldDelegate.color != color || oldDelegate.textColor != textColor;
}
class DetectiveMode extends StatefulWidget {
  const DetectiveMode({super.key, required this.question, required this.onAnswer});
  final Question question;
  final ValueChanged<Object> onAnswer;
  @override
  State<DetectiveMode> createState() => _DetectiveModeState();
}
class _DetectiveModeState extends State<DetectiveMode> {
  final Set<int> _selected = <int>{};
  @override
  Widget build(BuildContext context) {
    final List<String> words = (widget.question.content['words'] as List<dynamic>).cast<String>();
    // Practice hints are public; only server grading can award persistent XP.
    final Set<int> errors = ((widget.question.content['error_indices'] as List<dynamic>?) ?? <int>[1,5]).cast<int>().toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      const ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text('Školský príspevok'), subtitle: Text('Nájdi chyby • tréning pravopisu')),
      Wrap(spacing: 6, runSpacing: 8, children: List<Widget>.generate(words.length, (int index) {
        final bool selected = _selected.contains(index);
        final bool correct = errors.contains(index);
        return Semantics(button: true, selected: selected, label: '${words[index]}${selected ? (correct ? ', odhalená chyba' : ', správne slovo — nesprávny výber') : ''}', child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() { selected ? _selected.remove(index) : _selected.add(index); }),
          child: AnimatedContainer(duration: const Duration(milliseconds: 220), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: selected ? (correct ? Colors.green.shade800 : Colors.red.shade800) : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(words[index], style: TextStyle(fontSize: 19, color: selected ? Colors.white : null)), if (selected) Icon(correct ? Icons.check : Icons.close, color: Colors.white, size: 18)])),
        ));
      })),
      const SizedBox(height: 24), Text('Vybrané slová: ${_selected.length}'),
      FilledButton(onPressed: _selected.isEmpty ? null : () => widget.onAnswer(_selected.toList()..sort()), child: const Text('Potvrdiť nález')),
    ]);
  }
}
class GeoClick extends StatefulWidget {
  const GeoClick({super.key, required this.question, required this.onAnswer});
  final Question question;
  final ValueChanged<Object> onAnswer;
  @override
  State<GeoClick> createState() => _GeoClickState();
}
class _GeoClickState extends State<GeoClick> {
  Offset? _point;
  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
    const Text('Ťukni na mapu. Značku môžeš pred potvrdením presunúť.'),
    const SizedBox(height: 16),
    Semantics(label: 'Zjednodušená mapa Slovenska. Dotyková úloha; vyžaduje vizuálnu orientáciu.', child: AspectRatio(aspectRatio: 2, child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      return GestureDetector(onTapDown: (TapDownDetails details) => setState(() => _point = Offset((details.localPosition.dx / constraints.maxWidth).clamp(0,1), (details.localPosition.dy / constraints.maxHeight).clamp(0,1))),
        child: Stack(fit: StackFit.expand, children: <Widget>[
          Image.asset(widget.question.content['map'] as String, fit: BoxFit.fill),
          if (_point != null) Positioned(left: _point!.dx * constraints.maxWidth - 16, top: _point!.dy * constraints.maxHeight - 30, child: const Icon(Icons.location_on, size: 32, color: Colors.deepOrange)),
        ]));
    }))),
    const SizedBox(height: 20), FilledButton(onPressed: _point == null ? null : () => widget.onAnswer(<String,double>{'x':_point!.dx,'y':_point!.dy}), child: const Text('Potvrdiť polohu')),
    const Text('Tréningová mapa • tolerancia 6 % rozmerov obrázka'),
  ]);
}
