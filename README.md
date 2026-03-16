# Memory2CARE
Augmented Reality Mobile Application for Cognitive Rehabilitation in Oncology

## Overview

Memory2CARE is a mobile application prototype designed to support cognitive rehabilitation for oncology patients experiencing prospective memory difficulties, commonly referred to as *chemobrain*.

The application aims to assist users in remembering future actions such as taking medication or attending appointments by using contextual cues, including augmented reality and location-based triggers.

Instead of relying solely on traditional calendar reminders, Memory2CARE provides intelligent and context-aware prompts that appear at the right time and place.

---

## Problem Statement

Breast cancer treatments such as chemotherapy often cause cognitive side effects known as **chemobrain**, which can impair memory and executive functions.

One of the most affected abilities is **prospective memory**, the capacity to remember to perform actions in the future (e.g., taking medication at the correct time).

Current digital tools mainly rely on basic reminders and do not leverage contextual information to support memory recall.

Memory2CARE aims to address this gap by combining task management with contextual and augmented reality cues.

---

## Project Objective

The goal of the project is to develop a **functional mobile prototype** that supports daily routines and medication adherence through:

- intelligent task management
- contextual reminders
- augmented reality visual cues
- accessible and user-friendly interface design

The application is intended as a **proof-of-concept prototype** for future clinical studies.

---

## Core Features

### Intelligent Task Manager

- Create and manage routines and reminders
- Schedule medication intake
- Track daily tasks and routines
- Simple and accessible interface

### Augmented Reality Module

- Image-based recognition of medication packaging
- Contextual visual cues displayed through the camera
- Display of relevant medication information such as:
  - medication name
  - last intake
  - next scheduled intake

### Contextual Triggers

Reminders can be triggered by:

- **Time-based events** (scheduled reminders)
- **Location-based triggers** (e.g., entering the kitchen)
- **Image recognition triggers** (e.g., recognizing a medication box)

### Logging and Usage Tracking

- Log completed or missed tasks
- Record interactions with reminders
- Store anonymized usage data for future clinical analysis

### Accessible UI/UX

The application will prioritize accessibility for users who may have:

- cognitive difficulties
- reduced attention
- low digital literacy

The interface will therefore focus on:

- simple navigation
- clear visual cues
- minimal cognitive load
- large and easy-to-use controls

---

## Example Use Case

1. A user schedules a medication routine in the application.
2. The user associates the medication packaging with the routine.
3. When the camera recognizes the medication box:
   - The application displays contextual information such as:
     - medication name
     - last intake
     - next scheduled intake
4. The user can quickly confirm that the medication has been taken.

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Mobile Framework | Flutter |
| Programming Language | Dart |
| Augmented Reality | ARCore / ARKit (via Flutter plugins) |
| Local Database | SQLite |
| Notifications | Flutter Local Notifications |
| Location Services | Geolocation / Geofencing |
| Image Recognition | ML Kit or TensorFlow Lite |

---

## Development Methodology

The project follows an **Agile development approach** with regular iterations and validation meetings with the research team.

### Phase 1 – Requirements Elicitation (Weeks 1–3)

- Detailed requirements analysis with the psychology research team
- Review of the proof-of-concept prototype
- Technology stack selection

### Phase 2 – UI/UX Prototyping and Architecture (Weeks 4–6)

- Low and medium fidelity interface prototypes
- Navigation and workflow design
- Software architecture definition

### Phase 3 – Iterative Development (Weeks 7–12)

Development will be organized into development sprints.

**Sprint A**

- Task manager
- notifications
- local database
- user authentication

**Sprint B**

- AR features
- image recognition
- location-based triggers
- multimedia integration

### Phase 4 – Testing and Documentation (Weeks 13–15)

- System testing
- bug fixing
- technical documentation
- handover to the research team

---

## Project Status

Current Stage: **Initial project definition and technology selection**

Next Steps:

- Validate initial requirements with the research team
- Define system architecture
- Begin UI/UX prototyping

---

## Open Questions

Some aspects of the system still require clarification with the research team:

- Should medication data be entered manually or extracted automatically from packaging?
- What level of AR interaction is expected for the prototype?
- What privacy constraints should apply to usage logging?
- Should the application support both Android and iOS in the prototype phase?

---