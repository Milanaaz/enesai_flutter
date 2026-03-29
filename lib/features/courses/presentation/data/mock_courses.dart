import 'package:dipl/features/courses/presentation/models/course_models.dart';

const List<String> courseLevels = <String>['A1', 'A2', 'B1', 'B2'];

const Map<CourseType, String> courseTypeLabels = <CourseType, String>{
  CourseType.general: 'Общий',
  CourseType.ort: 'ОРТ',
  CourseType.speaking: 'Разговорный',
  CourseType.business: 'Деловой',
  CourseType.grammar: 'Грамматика',
  CourseType.reading: 'Чтение',
  CourseType.pronunciation: 'Произношение',
};

const List<CourseInfo> mockCourses = <CourseInfo>[
  CourseInfo(
    id: 'course-b1-general',
    title: 'B1 · Кыргызский язык',
    description:
        'Курс помогает перейти на уверенный средний уровень: разговор, аудирование и базовая грамматика для повседневной жизни.',
    coverLabel: 'B1',
    level: 'B1',
    type: CourseType.general,
    lessonCount: 18,
    totalMinutes: 620,
    status: CourseStatus.inProgress,
    goals: <String>[
      'Понимать основную мысль диалогов',
      'Строить длинные фразы в бытовых темах',
      'Укрепить словарный запас для общения',
    ],
    audience: <String>[
      'Для тех, кто завершил A2 и хочет перейти к практике',
      'Для студентов, готовящихся к учебе в Кыргызстане',
    ],
    modules: <CourseModule>[
      CourseModule(
        id: 'm1',
        title: 'Модуль 1. Повседневные ситуации',
        progress: 1,
        lessons: <LessonInfo>[
          LessonInfo(
            id: 'l1',
            title: 'Знакомство и представление',
            durationMinutes: 35,
            words: <LessonWord>[
              LessonWord(
                value: 'таанышуу',
                translation: 'знакомство',
                transcription: '[таанышуу]',
                example: 'Биз бүгүн таанышуу темасын өтөбүз.',
              ),
              LessonWord(
                value: 'мекеме',
                translation: 'учреждение',
                transcription: '[мекеме]',
                example: 'Ал жаңы мекемеде иштейт.',
              ),
            ],
          ),
          LessonInfo(
            id: 'l2',
            title: 'В магазине',
            durationMinutes: 28,
            words: <LessonWord>[],
          ),
        ],
      ),
      CourseModule(
        id: 'm2',
        title: 'Модуль 2. Учеба и работа',
        progress: .6,
        lessons: <LessonInfo>[
          LessonInfo(
            id: 'l3',
            title: 'В университете',
            durationMinutes: 30,
            words: <LessonWord>[],
          ),
          LessonInfo(
            id: 'l4',
            title: 'На собеседовании',
            durationMinutes: 34,
            words: <LessonWord>[],
          ),
        ],
      ),
    ],
  ),
  CourseInfo(
    id: 'course-a2-grammar',
    title: 'A2 · Грамматика без страха',
    description:
        'Пошаговый курс по грамматике: времена, падежи, связки и частые ошибки в речи.',
    coverLabel: 'A2',
    level: 'A2',
    type: CourseType.grammar,
    lessonCount: 14,
    totalMinutes: 470,
    status: CourseStatus.notStarted,
    goals: <String>[
      'Понять структуру простых и сложных предложений',
      'Снизить количество грамматических ошибок',
    ],
    audience: <String>['Для начинающих и продолжающих уровня A1-A2'],
    modules: <CourseModule>[
      CourseModule(
        id: 'm1',
        title: 'Модуль 1. Базовые конструкции',
        progress: 0,
        lessons: <LessonInfo>[
          LessonInfo(
            id: 'l1',
            title: 'Порядок слов',
            durationMinutes: 26,
            words: <LessonWord>[],
          ),
        ],
      ),
    ],
  ),
  CourseInfo(
    id: 'course-b2-speaking',
    title: 'B2 · Разговорный интенсив',
    description:
        'Фокус на беглости речи, сложных диалогах и аргументации в бытовых и рабочих темах.',
    coverLabel: 'B2',
    level: 'B2',
    type: CourseType.speaking,
    lessonCount: 20,
    totalMinutes: 760,
    status: CourseStatus.completed,
    goals: <String>['Свободно поддерживать диалог', 'Уверенно выступать'],
    audience: <String>[
      'Для тех, кто уже уверенно говорит и хочет довести речь',
    ],
    modules: <CourseModule>[
      CourseModule(
        id: 'm1',
        title: 'Модуль 1. Аргументация',
        progress: 1,
        lessons: <LessonInfo>[
          LessonInfo(
            id: 'l1',
            title: 'Сравнение мнений',
            durationMinutes: 32,
            words: <LessonWord>[],
          ),
        ],
      ),
    ],
  ),
];

String statusLabel(CourseStatus status) {
  return switch (status) {
    CourseStatus.notStarted => 'Не начат',
    CourseStatus.inProgress => 'В процессе',
    CourseStatus.completed => 'Завершен',
  };
}
