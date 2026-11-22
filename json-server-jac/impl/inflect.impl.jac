impl plural_rules -> list[Rule] {
    keep = [
        P_MEN,
        P_PEOPLE,
        P_CHILDREN,
        P_TIA,
        P_ANALYSES,
        P_DATABASES,
        P_DRIVES,
        P_HIVES,
        P_CURVES,
        P_LRVES,
        P_FOVES,
        P_AEIOUYIES,
        P_SERIES,
        P_MOVIES,
        P_XES,
        P_MICE,
        P_BUSES,
        P_OES,
        P_SHOES,
        P_CRISES,
        P_OCTOPUSES,
        P_ALIASES,
        P_SUMMONSES,
        P_OXEN,
        P_MATRICES,
        P_FEET,
        P_TEETH,
        P_GEESE,
        P_QUIZZES,
        P_WHEREASES,
        P_CRITERIA,
        P_GENERA,
    ];
    rules = [Rule(pattern=p) for p in keep];
    pairs: list[tuple[re.Pattern, str]] = [
        (S_MAN, r"\g<1>en"),
        (S_PERSON, r"\g<1>ople"),
        (S_CHILD, r"\g<1>ren"),
        (S_DRIVE, r"\g<1>s"),
        (S_OX, r"\g<1>en"),
        (S_AXIS, r"\g<1>es"),
        (S_OCTOPUS, r"\g<1>uses"),
        (S_ALIAS, r"\g<1>es"),
        (S_SUMMONS, r"\g<1>es"),
        (S_BUS, r"\g<1>ses"),
        (S_BUFFALO, r"\g<1>oes"),
        (S_TIUM, r"\g<1>a"),
        (S_SIS, "ses"),
        (S_FFE, r"\g<1>\g<2>ves"),
        (S_FOCUS, r"\g<1>es"),
        (S_HIVE, r"\g<1>ves"),
        (S_AEIOUYY, r"\g<1>ies"),
        (S_MATRIX, r"\g<1>ices"),
        (S_VERTEX, r"\g<1>ices"),
        (S_X, r"\g<1>es"),
        (S_MOUSE, r"\g<1>ice"),
        (S_FOOT, "feet"),
        (S_TOOTH, "teeth"),
        (S_GOOSE, "geese"),
        (S_QUIZ, r"\g<1>zes"),
        (S_WHEREAS, r"\g<1>es"),
        (S_CRITERION, r"\g<1>a"),
        (S_GENUS, "genera"),
        (S_S, "s"),
        (S_COMMON, "s"),
    ];
    for (p, r) in pairs {
        rules.append(Rule(pattern=p, replacement=r));
    }
    return rules;
}

impl singular_rules -> list[Rule] {
    keep = [
        S_MAN,
        S_PERSON,
        S_CHILD,
        S_DRIVE,
        S_OX,
        S_AXIS,
        S_OCTOPUS,
        S_ALIAS,
        S_SUMMONS,
        S_BUS,
        S_BUFFALO,
        S_TIUM,
        S_SIS,
        S_FFE,
        S_FOCUS,
        S_HIVE,
        S_AEIOUYY,
        S_X,
        S_MATRIX,
        S_MOUSE,
        S_FOOT,
        S_TOOTH,
        S_GOOSE,
        S_QUIZ,
        S_WHEREAS,
        S_CRITERION,
        S_GENUS,
    ];
    rules = [Rule(pattern=p) for p in keep];
    pairs: list[tuple[re.Pattern, str]] = [
        (P_MEN, r"\g<1>an"),
        (P_PEOPLE, r"\g<1>rson"),
        (P_CHILDREN, r"\g<1>"),
        (P_DATABASES, r"\g<1>"),
        (P_DRIVES, r"\g<1>"),
        (P_GENERA, "genus"),
        (P_CRITERIA, r"\g<1>on"),
        (P_TIA, r"\g<1>um"),
        (P_ANALYSES, r"\g<1>\g<2>sis"),
        (P_HIVES, r"\g<1>ve"),
        (P_CURVES, r"\g<1>"),
        (P_LRVES, r"\g<1>f"),
        (P_AVES, r"\g<1>ve"),
        (P_FOVES, r"\g<1>fe"),
        (P_MOVIES, r"\g<1>ovie"),
        (P_AEIOUYIES, r"\g<1>y"),
        (P_SERIES, r"\g<1>eries"),
        (P_XES, r"\g<1>"),
        (P_MICE, r"\g<1>ouse"),
        (P_BUSES, r"\g<1>"),
        (P_OES, r"\g<1>"),
        (P_SHOES, r"\g<1>"),
        (P_CRISES, r"\g<1>is"),
        (P_OCTOPUSES, r"\g<1>us"),
        (P_ALIASES, r"\g<1>"),
        (P_SUMMONSES, r"\g<1>"),
        (P_OXEN, r"\g<1>"),
        (P_MATRICES, r"\g<1>ix"),
        (P_VERTICES, r"\g<1>ex"),
        (P_FEET, "foot"),
        (P_TEETH, "tooth"),
        (P_GEESE, "goose"),
        (P_QUIZZES, r"\g<1>"),
        (P_WHEREASES, r"\g<1>"),
        (P_SS, "ss"),
        (P_S, ""),
    ];
    for (p, r) in pairs {
        rules.append(Rule(pattern=p, replacement=r));
    }
    return rules;
}

impl apply_rules(word: str, rules: list[Rule]) -> str {
    if word.lower() in UNCOUNTABLE {
        return word;
    }
    for rule in rules {
        if rule.pattern.search(word) is not None {
            if rule.replacement is not None {
                return rule.pattern.sub(rule.replacement, word);
            }
            return word;
        }
    }
    return word;
}

impl pluralize(word: str) -> str {
    return apply_rules(word, PLURAL_RULES);
}

impl singularize(word: str) -> str {
    return apply_rules(word, SINGULAR_RULES);
}
