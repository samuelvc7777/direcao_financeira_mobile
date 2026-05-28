---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: For this project, new implementation SHOULD normally include tests. Only omit test tasks if the feature truly has no meaningful automated coverage path, and justify that in the task list.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/app/...` and `test/...`
- **Presentation**: `lib/app/presentation/modules/<feature>/`
- **Domain**: `lib/app/domain/...`
- **Data**: `lib/app/data/...`
- **Tests**: mirror the affected layer/module as closely as possible

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Contracts from contracts/
  
  Tasks in this repository should naturally reflect:
  - Clean Architecture boundaries
  - GetX bindings/controllers for presentation state
  - View/page separated from widgets
  - Tests by touched layer
  ============================================================================
-->

## Phase 1: Setup (Shared Structure)

**Purpose**: Prepare module structure and dependency wiring without violating architecture boundaries

- [ ] T001 Identify target module and affected layer boundaries from plan.md
- [ ] T002 Create or adjust feature paths under lib/app/presentation/modules/[feature]/
- [ ] T003 [P] Create or adjust supporting paths in lib/app/domain/ and lib/app/data/ as required
- [ ] T004 [P] Prepare mirrored test paths under test/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core structures that MUST be in place before any user story is completed

- [ ] T005 Define or update domain contracts in lib/app/domain/repositories/ and lib/app/domain/usecases/
- [ ] T006 [P] Create or update entities/services in lib/app/domain/entities/ or lib/app/domain/services/
- [ ] T007 [P] Create or update datasource/repository implementations in lib/app/data/
- [ ] T008 Create or update GetX binding for the feature in lib/app/presentation/modules/[feature]/[feature]_binding.dart
- [ ] T009 Create or update controller skeleton in lib/app/presentation/modules/[feature]/[feature]_controller.dart

**Checkpoint**: Foundation ready - user story implementation can now proceed without collapsing layers

---

## Phase 3: User Story 1 - [Title] (Priority: P1) MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1

- [ ] T010 [P] [US1] Add domain test coverage in test/app/domain/[path]_test.dart
- [ ] T011 [P] [US1] Add controller or presentation test coverage in test/app/presentation/modules/[feature]/[path]_test.dart

### Implementation for User Story 1

- [ ] T012 [P] [US1] Implement or refine use case/service in lib/app/domain/usecases/[file].dart
- [ ] T013 [P] [US1] Implement or refine repository/datasource support in lib/app/data/[path]/[file].dart
- [ ] T014 [US1] Update controller state flow in lib/app/presentation/modules/[feature]/[feature]_controller.dart
- [ ] T015 [US1] Update page/view macro structure in lib/app/presentation/modules/[feature]/[feature]_view.dart
- [ ] T016 [P] [US1] Extract or refine visual sections in lib/app/presentation/modules/[feature]/widgets/[widget_file].dart
- [ ] T017 [US1] Validate loading, empty, success and error states for the story

**Checkpoint**: User Story 1 should now be independently functional and testable

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2

- [ ] T018 [P] [US2] Add domain or data coverage in test/app/[layer]/[path]_test.dart
- [ ] T019 [P] [US2] Add presentation/controller/widget coverage in test/app/presentation/modules/[feature]/[path]_test.dart

### Implementation for User Story 2

- [ ] T020 [P] [US2] Update domain artifacts in lib/app/domain/[path]/[file].dart
- [ ] T021 [P] [US2] Update data artifacts in lib/app/data/[path]/[file].dart
- [ ] T022 [US2] Update controller flow in lib/app/presentation/modules/[feature]/[feature]_controller.dart
- [ ] T023 [US2] Update view/widgets in lib/app/presentation/modules/[feature]/ and widgets/

**Checkpoint**: User Stories 1 and 2 should both work independently

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Final refinements that affect multiple stories

- [ ] TXXX [P] Refine responsiveness across affected views in lib/app/presentation/modules/[feature]/
- [ ] TXXX [P] Clean controller/view/widget responsibilities where needed
- [ ] TXXX Run and fix automated tests for affected layers
- [ ] TXXX Update documentation or usage notes if the feature changes developer navigation or behavior

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Stories (Phase 3+)**: Depend on foundational architecture being in place
- **Polish (Final Phase)**: Depends on all intended user stories being complete

### Within Each User Story

- Domain/data support before final presentation wiring
- Binding/controller readiness before full view integration
- View macro structure before widget extraction is finalized
- Tests should be added alongside the touched layers and validated before closing the story

### Parallel Opportunities

- Tasks marked `[P]` can run in parallel when they do not touch the same files
- Domain and data artifacts often parallelize well if they are in separate files
- Widget extraction tasks can parallelize after macro layout decisions are stable

---

## Implementation Strategy

### MVP First

1. Complete Setup
2. Complete Foundational layer work
3. Deliver User Story 1 end-to-end through `domain -> data -> controller -> view/widgets`
4. Validate responsiveness and tests before moving on

### Incremental Delivery

1. Preserve architecture first
2. Deliver one story at a time with complete vertical slice
3. Keep each story independently testable and visually coherent

---

## Notes

- Controllers control views; they do not become repositories, datasources or business engines
- Bindings are the official dependency composition point
- Views own macro structure; widgets own extracted visual composition
- Domain rules stay out of presentation
- Always prefer file paths that match the existing module structure instead of inventing parallel trees
