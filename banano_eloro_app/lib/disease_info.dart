/// BORRADOR para revisión del usuario — no es contenido fitosanitario
/// definitivo. Redactado a partir de lo documentado en el README de
/// HuggingFace (JoelVela/banano-eloro-classifier) más conocimiento general
/// de cada enfermedad; falta validación final.
const Map<String, String> diseaseDescriptions = {
  'Sigatoka':
      'Enfermedad fúngica foliar muy común y endémica en El Oro. Se presenta '
      'en estadio temprano (lesiones individuales bien definidas) o avanzado '
      '(necrosis extensa de la hoja). El modelo puede confundir el estadio '
      'avanzado con Panama Disease o Moko.',
  'Cordana':
      'Mancha foliar fúngica de relevancia media en la provincia. Produce '
      'lesiones en las hojas generalmente menos severas que las de Sigatoka, '
      'aunque visualmente pueden confundirse con otras manchas fúngicas.',
  'Pestalotiopsis':
      'Enfermedad fúngica foliar de relevancia media en El Oro. Genera '
      'manchas/lesiones en las hojas que pueden confundirse con otras '
      'enfermedades foliares fúngicas similares.',
  'Healthy':
      'Hoja sana, sin signos visibles de enfermedad ni daño de plagas. '
      'Se usa como clase de control para comparar contra las demás '
      'categorías.',
  'Moko':
      'Enfermedad bacteriana (Ralstonia solanacearum) bajo vigilancia y '
      'cuarentena activa en El Oro por su alto riesgo fitosanitario. '
      'Relevancia alta: una sospecha debería confirmarse en laboratorio.',
  'Panama_Disease':
      'Marchitez vascular causada por el hongo Fusarium, asociada a la Raza '
      'Tropical 4 confirmada en la región en diciembre de 2025. Relevancia '
      'alta: es una enfermedad de cuarentena con impacto severo en el '
      'cultivo.',
  'Insect_Pest':
      'Daño foliar causado por plagas de insectos, no por un hongo o '
      'bacteria. Relevancia media; el patrón visual del daño difiere del de '
      'las lesiones fúngicas.',
};
