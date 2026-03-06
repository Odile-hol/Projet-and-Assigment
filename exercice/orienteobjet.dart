
enum Priority { low, medium, high, urgent }
class Task {
  final String description; 
  final Priority priority; 
  final String? dueDate; 
  final String? completedDate; 
  final List<String>? tags; 
  final double? estimatedHours; 

  Task({
    required this.description,
    this.priority = Priority.medium, // Valeur par défaut
    this.dueDate,
    this.completedDate,
    this.tags,
    this.estimatedHours,
  });

  @override
  String toString() {
    return 'Task(description: $description, priority: $priority, dueDate: $dueDate, completedDate: $completedDate, tags: $tags, estimatedHours: $estimatedHours)';
  }
}


class Project {
  final String name; // Toujours requis
  final String? description; // Nullable (peut être vide)
  final double? budget; // Nullable (budget optionnel)
  final List<Task> tasks; // Toujours une liste (même vide)

  Project({
    required this.name,
    this.description,
    this.budget,
    List<Task>? tasks,
  }) : tasks = tasks ?? []; // Initialise avec une liste vide si null

  @override
  String toString() {
    return 'Project(name: $name, description: $description, budget: $budget, tasks: $tasks)';
  }
}

void main() {
  print("=" * 50);
  print("🏆 PROJECT MILESTONE 1: GESTIONNAIRE DE TÂCHES");
  print("=" * 50);

  // -----------------------------------------------------------------
  // CRÉATION DES INSTANCES DE TÂCHES (avec différentes nullabilités)
  // -----------------------------------------------------------------

  // Tâche 1: Complète (tous les champs renseignés)
  final task1 = Task(
    description: "Préparer présentation Kotlin",
    priority: Priority.high,
    dueDate: "2024-12-15",
    completedDate: null, // Pas encore terminée
    tags: ["travail", "présentation", "kotlin"],
    estimatedHours: 4.5,
  );

  // Tâche 2: Simple (minimum de champs)
  final task2 = Task(
    description: "Acheter du lait",
    priority: Priority.medium,
    dueDate: "2024-12-10",
    completedDate: null,
    tags: null, // Pas de tags
    estimatedHours: null, // Pas d'estimation
  );

  // Tâche 3: Terminée (avec date de complétion)
  final task3 = Task(
    description: "Ranger le bureau",
    priority: Priority.low,
    dueDate: "2024-12-05",
    completedDate: "2024-12-04", // Terminée hier
    tags: ["maison", "organisation"],
    estimatedHours: 1.0,
  );

  // Tâche 4: Sans date d'échéance
  final task4 = Task(
    description: "Apprendre Flutter",
    priority: Priority.medium,
    dueDate: null, // Pas de date limite
    completedDate: null,
    tags: ["formation", "mobile"],
    estimatedHours: 20.0,
  );

  // -----------------------------------------------------------------
  // CRÉATION DES PROJETS
  // -----------------------------------------------------------------

  // Projet 1: Travail
  final workProject = Project(
    name: "Projet Formation Kotlin",
    description: "Préparation et livraison d'une formation Kotlin",
    budget: 1500.0,
    tasks: [task1, task4],
  );

  // Projet 2: Personnel
  final personalProject = Project(
    name: "Tâches personnelles",
    description: null, // Pas de description
    budget: null, // Pas de budget
    tasks: [task2, task3],
  );

  // Projet 3: Sans description ni budget
  final futureProject = Project(
    name: "Projets futurs",
    description: null,
    budget: null,
    // Pas de tâches pour l'instant
  );

  
  print("\n📋 LISTE DES TÂCHES CRÉÉES:");
  print("-" * 40);

  void printTask(int index, Task task) {
    print("Tâche #$index:");
    print("  📝 Description : ${task.description}");
    print("  ⚡ Priorité : ${_priorityToString(task.priority)}");
    print("  📅 Échéance : ${task.dueDate ?? "Non définie"}");
    print("  ✅ Terminée le : ${task.completedDate ?? "En cours"}");
    print("  🏷️ Tags : ${task.tags ?? "Aucun"}");
    print(
      "  ⏱️ Heures estimées : ${task.estimatedHours != null ? "${task.estimatedHours}h" : "Non estimées"}",
    );
    print("");
  }

  [task1, task2, task3, task4].asMap().forEach((index, task) {
    printTask(index + 1, task);
  });

  print("\n📂 LISTE DES PROJETS CRÉÉS:");
  print("-" * 40);

  final projects = [workProject, personalProject, futureProject];
  projects.asMap().forEach((index, project) {
    print("Projet #${index + 1}: ${project.name}");
    print("  📄 Description : ${project.description ?? "Aucune description"}");
    print(
      "  💰 Budget : ${project.budget != null ? "${project.budget} €" : "Non défini"}",
    );
    print("  📊 Nombre de tâches : ${project.tasks.length}");
    if (project.tasks.isNotEmpty) {
      print("  📋 Tâches:");
      for (var task in project.tasks) {
        print(
          "    • ${task.description} (${_priorityToString(task.priority)})",
        );
      }
    }
    print("");
  });


  print("\n📊 STATISTIQUES D'UTILISATION DES NULLABLES:");
  print("-" * 40);

  final allTasks = [task1, task2, task3, task4];

  final tasksWithDueDate = allTasks.where((t) => t.dueDate != null).length;
  final tasksCompleted = allTasks.where((t) => t.completedDate != null).length;
  final tasksWithTags = allTasks.where((t) => t.tags != null).length;
  final tasksWithEstimation = allTasks
      .where((t) => t.estimatedHours != null)
      .length;

  print("Tâches avec date d'échéance : $tasksWithDueDate/4");
  print("Tâches terminées : $tasksCompleted/4");
  print("Tâches avec tags : $tasksWithTags/4");
  print("Tâches avec estimation : $tasksWithEstimation/4");

  print("\n" + "=" * 50);
  print("✅ FIN DU MILESTONE 1");
  print("=" * 50);
}

// Fonction utilitaire pour convertir l'enum Priority en String
String _priorityToString(Priority priority) {
  switch (priority) {
    case Priority.low:
      return "LOW";
    case Priority.medium:
      return "MEDIUM";
    case Priority.high:
      return "HIGH";
    case Priority.urgent:
      return "URGENT";
  }
}
