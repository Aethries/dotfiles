---
name: godot-gdscript
description: "Godot 4.x & GDScript 2.0 architecture: static typing, scene-tree composition, signal decoupling, state machines, physics process vs idle process, and Godot MCP integration. Use when building Godot games or tools."
---

# Godot 4.x & GDScript Architecture

Best practices for building maintainable, performant Godot 4 games and tooling using GDScript 2.0.

## Core Rules

1. **Static Typing & Performance**:
   - Always enforce static typing for variables, parameters, and return types (`var speed: float = 100.0`, `func move(delta: float) -> void`).
   - Use typed arrays (`Array[Node3D]`) and typed dictionaries where applicable.
   - Cache node references using `@onready var name: Type = $Path` or `@export var node: Type`. Avoid runtime `get_node()` in loops.

2. **Node Composition & Signals**:
   - Favor composition over deep inheritance hierarchies. Break complex entities into reusable child scenes and components.
   - Signal down, call down, signal up: Parent nodes invoke methods on children; children emit signals to notify parents.
   - Decouple systems using custom signals (`signal health_changed(new_health: int)`). Avoid direct cross-scene hardcoded references.

3. **Loop & Physics Hygiene**:
   - Place movement, collisions, and Rigidbody interactions inside `_physics_process(delta: float)`.
   - Place animations, UI updates, and visual effects inside `_process(delta: float)`.
   - Use delta time for all rate-based calculations (`position += velocity * delta`).
   - Use `queue_free()` for entity deletion; never rely on raw garbage collection.

4. **Resource Management**:
   - Use custom `Resource` scripts (`class_name ItemData extends Resource`) for data-driven stats, inventories, and configs.
   - Avoid circular scene/resource dependencies.
