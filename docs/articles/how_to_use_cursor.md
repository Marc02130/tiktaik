What is cursor and how it can help you?

For some, software development might seem like a mystical art reserved only for the exceptionally gifted. While it does require significant time, strategic planning, and perseverance, it is also a process that can be systematically mapped and improved. AI-enhanced tools are revolutionizing this landscape, reducing toil, streamlining workflows, and opening up new possibilities for people who may have once found software development unattainable. Now, AI-native IDEs like Cursor represent the next significant leap forward — a bridge between human creativity and technological innovation.

If you’re a seasoned engineer looking to amplify your capabilities, an entrepreneur with a vision, or someone who’s always wanted to build but felt intimidated by programming, the barrier to entry has never been lower. Cursor is more than just an IDE; it’s a transformative tool that leverages Large Language Models to assist with all aspects of development. Whether you want to write code, edit sections of your project, understand complex repository interconnections, or reduce development time, these AI-powered tools are democratizing the art of software creation.

The true power lies not in replacing human ingenuity, but in augmenting it. By providing intelligent assistance, contextual understanding, and rapid iteration capabilities, tools like Cursor empower developers to turn ideas into functional software more efficiently than ever before. The question is no longer “Can I build this?” but “What will I build first?”
Best Practices — Overview

    Use templates as a foundation to build on
    Break down project into small tasks
    Use cursor for functions & v0 for UI
    git commit every task
    Planning ahead — Measure twice cut once
    Context is King — No uneducated guesses
    Prompt Engineering — Clear, Simple, Well Defined
    Structure Outputs — Use Pydantic Validation to maximize determinism

Building on a Foundation

Leverage existing code templates

    Start with boilerplate (auth, DB, payments)
    Build on top of proven foundations
    Saves time on repetitive tasks

LLMs are particularly good at

    Documenting, Explaining and Teaching Code
    Adding comments to code
    Duplicating what already exists

Ask another AI to help, if cursor gets stuck
Planning ahead

Before you write a single line of code or ask AI, first figure out…

    What you are going to build
    What it (kind of) looks like
    -> sketch a system diagram for backend or wireframe for frontend
    Don’t assume LLM knows best … it is the copilot and YOU are the boss

    Know what packages you are going to use ahead of time

    Project Overview: High-level overview of the project including req. packages
    Core Functionalities: List of Functionalities the application should include, as well as modules/components for each
    Doc: Document which packages you are going to use with specific code examples from actual documentation that are relevant
    Current File Structure:
    - Use a template as the base of the project
    - Grab top level file structure (e.g. `tree L -2 -I ‘node_modules|.git’`)
    — FastAPI for backend
    — Nodejs for frontend

Draft a PRD (Product Requirement Document) outline — instrustions.md

# Project Overview
...
# Core Functionalities
...
# Doc
...
# Current File Structure
...

2. Research for package: Grab code examples from package docs to add into Doc section of PRD and/or add to Docs using “@”

3. Design Project Structure: Ask AI to create a file structure based on the PRD, example template structure and with as few files as possible.

4. Write Final PRD with draft PRD, ask it add detailed implementation requirements and new suggested file structure into markdown file.

Use this PRD to align the AI outputs to your project needs by adding it to Docs and referencing whenever you need to or by adding it to .cursorrules file.
Context
Rules for AI & .cursorrules

    Set global rules with “Rules for AI”
    Set project specific directions for cursor AI w/ .cursorrules file
    Place .cursorrules in the root of your project like an .env file

Be detailed/specific as possible
Tagging @Docs

Files, Folders, Code, Docs, Git, Codebase, Web, Chat, Definitions, Links

Humans naturally pick up context from their environment, settings, social cues, senses, and experience. I don’t know about you all, but I rely heavily on this skill to understand what others are trying to communicate, and I often depend on context to convey the wittiness of a joke. When something seems wrong, our intuition triggers automatic checks to verify expected elements are present. LLMs do not have this ability, sense or experience. It is important to remember that they are just a tool. Until we use them properly and effectively, they will not be consistently helpful to us. It is important to be as explicit, restrictive and unambiguous as possible.

How do we compensate for this?

LLMs are trained on input-output pairs, excel at following instructions, and effectively retain semantic relationships. Effective use of LLMs to generate code that aligns to our expectations requires prompt engineering.
Prompt Engineering for Code Generation

In general, prompt engineering promotes writing simple, clear and well defined instructions for your prompt to complete a given task. This epitomizes all other prompt engineering knowledge.

When it comes to writing code it is important to follow best practices from software engineering, particularly good documentation. Well-documented code provides valuable context through function definitions, schemas, field descriptions, variable types, and their relationships to other code components. Having descriptive comments with clarity and detail will go even further to help define all components when they are inevitably used as puzzle pieces in the LLM’s context window. Using a package that is well documented is easier for the LLM to understand and work with, especially if it hasn’t seen it before in it’s pre-training.

Writing clear instructions in your prompt with well defined terms and variables is going to disambiguate your instruction from the possible set of misinterpretations. Including strict structure and specifications for your inputs and outputs using schemas will further eliminate the chance a model has to write something other than what you have instructed. Keeping the scope of the task as small and atomic as possible, while satisfying the minimum set of requirements, will ensure that errors from the margin of interpretation of possible implementations are not compounding. Keeping these steps as small as possible will also make it easier to make progress incrementally and make intervention with human feedback much simpler.
What is Chain of Thought?

Chain of thought (CoT) is a prompting technique that enhances a model’s ability to handle complex reasoning tasks by breaking problems into intermediate steps. While effective for reasoning, CoT can introduce variability and error propagation in structured workflows or code generation. By contrast, using chain of tasks, where each step is independently well-defined and validated, ensures a more deterministic and controlled process.

Chain of Tasks > Chain of Thought

To quote my friend and colleague Pano, a Senior AI Engineer, “using chain of tasks instead of chain of thought is a great way to reduce error.” By having well defined inputs and outputs for each task that an LLM is assigned to complete, and by injecting checkpoints throughout the series of tasks, you as the developer will have more control to validate the schema or the content with custom if-else logic thereby maintaining a greater level of determinism throughout the process. This is crucial for the multi-agent systems that Pano works on, but is just as important for us. We want to optimize for determinism, iteration speed and units of work that we as the human can easily validate (“looks good to me”).

Validation

“Pydantic is all you need.” This was such an insightful and popular topic, that Jason Liu presented it at the AI Engineer Summit two years in a row. Jason is the creator of instructor, the most popular Python library for working with structured outputs for LLMs. Our “Premium AI” research group members unanimously agree that using Pydantic for validation is the best way to ensure that structured data objects returned from a LLM match the provided schema. This makes error handling reliable. It’s better to provide feedback on specific fields that need tweaking when the JSON structure is correct, rather than dealing with completely malformed JSON outputs.
Pydantic validation

Pydantic allows developers to define schemas to ensure the output of LLMs response adheres to a predefined structure. By defining these custom types, developers can enforce consistency and reliability in the outputs generated by LLMs.

from pydantic import BaseModel
class Person(BaseModel):
name: str
age: int
Person(name="Christos", age="29")
>>> Person(name='Christos', age=29)
Person(name="Christos", age="29").age + 1
>>> 30

For more examples on preventing common LLM errors and improving reliability, check out this article about Steering LLMs with Pydantic.
Workflow

With all of that in mind, it’s helpful to remember that LLMs are actually better prompt engineers than we are. As described by my colleague Kunal, a successful serial GenAI entrepreneur, the recommended iteration process is as follows:

    Describe task.
    Ask model how it’d solve it.
    Tell model to write instruction prompt to reproduce.
    Have model explain its solution with reasoning for assurance.
    Use cursor to ‘apply’ solution directly into your script (if applicable).

(update: after writing this I am seeing the same best practices for other code generation tools — Replit Agent)

Based on my research, experience using Cursor and time spent working iteratively with LLMs, I’ve compiled these set of principles and practices that consistently produce better results. Whether you’re just starting with AI-assisted coding or looking to improve your workflow, these guidelines will help you get the most out of these tools.
AI Engineer Stack Overview

This stack serves as a minimum viable set of tools for building effective AI applications with a client-server setup:
Core Stack Components & Benefits

    Python: Python’s popularity in AI ensures extensive library support, ample example code, and compatibility with LLMs. In my opinion, it’s also the most intuitive language to learn and develop in.
    Pydantic: Ensures valid, schema-compliant outputs, minimizing LLM-related errors.
    FastAPI: Simple, Python package built with Pydantic that’s incredibly well documented and is an industry standard for building APIs.
    LLMs: They were trained for this.
    Cursor: Real-time AI-powered IDE, supercharging development.

Together, these tools provide a solid foundation for building, validating, and refining AI applications, maximizing productivity and reliability in AI-driven projects.
Summary
DO ✅

    Be Specific and Detailed.
    Define Output Format.
    Include Technical Requirements.
    Use the latest available model in Cursor for best results.

Tips

1 — Function Generation

    Include input/output types.
    Specify error handling requirements.
    Mention performance constraints.

2 — Testing Requirements

    Make sure the code it replaces works in the same way.
    “Write test cases to make sure implementation works as expected.”

3 — Iterative Refinement

    Start with basic implementation.
    Add “Please add error handling” or “Optimize for performance.”
    Request specific improvements or modifications.

Unleashing Your Potential

The power of AI-assisted development lies not in the technology itself, but in how we strategically harness it. By embracing the best practices outlined in this guide — being specific, maintaining context, validating rigorously, and thinking incrementally — you transform AI from a mere tool into a powerful extension of your creative capabilities.

The most critical insights for effective AI-powered development are deceptively simple yet profound:

    Break down complex problems into atomic, manageable tasks
    Provide clear, unambiguous instructions
    Use validation frameworks like Pydantic to ensure reliability
    Treat AI as a collaborative partner, not a replacement for human insight
    Iterate rapidly, learning and refining with each interaction

The future of software development is not about what AI can do, but about what you can achieve by thoughtfully integrating AI into your workflow. Start small, think big, and remember that the most impactful code solves real problems for real people. The tools are ready, the path is clear — what will you create?