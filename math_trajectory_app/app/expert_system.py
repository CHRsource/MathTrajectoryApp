MIN_CORRECT = 1

def get_next_test_and_trajectory(knowledge, topics_graph):
    testable_topics = []
    can_study_now = []
    blocked_topics = []

    for topic, data in topics_graph.items():
        if topic in knowledge:
            continue

        # проверяем, что все prereqs уже изучены
        prereqs = data['prerequisites']
        # сначала обрабатываем случай без prereqs
        if not prereqs:
            testable_topics.append(topic)
            break

        # далее — когда prereqs есть
        if all(knowledge.get(pr, False) for pr in prereqs):
            testable_topics.append(topic)
            break

    for topic, data in topics_graph.items():
        if knowledge.get(topic, False):
            continue

        prerequisites = data['prerequisites']
        unknown_prereqs = [pr for pr in prerequisites if not knowledge.get(pr, False)]

        if not unknown_prereqs:
            can_study_now.append(topic)
        else:
            blocked_topics.append((topic, unknown_prereqs))

    return {
        "next_test_topics": testable_topics,
        "can_study_now": can_study_now,
        "study_later_with_prereqs": blocked_topics
    }
