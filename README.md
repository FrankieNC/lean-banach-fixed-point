# lean-banach-fixed-point
This repository contains a Lean formalization of the **Banach Fixed Point Theorem** (also known as the **Contraction Mapping Theorem**), a fundamental result in metric space theory. The theorem guarantees the existence and uniqueness of fixed points for certain self-maps in complete metric spaces.

This project was completed as part of my coursework for the **Formalising Mathematics** module at **Imperial College London (2025)**. I chose this result because it's one of my personal favourites — elegant, powerful, and widely applicable across analysis and differential equations.

In addition to the Lean formalization, I have included a short report explaining the theorem, the formalization process, and some reflections on working with Lean and mathlib.

🎓 **Grade received**: 90%

## Getting Started

This project was developed using [Lean](https://leanprover-community.github.io/) and [mathlib](https://github.com/leanprover-community/mathlib).

If you're using **Lean 4**, note that this is a standalone Lean file. To make it work in your own environment:

1. Create a new Lake project:
    ```bash
    lake init banach_fixed_point
    cd banach_fixed_point
    ```

2. Set up mathlib dependencies:
    ```bash
    lake exe cache get
    ```

3. Copy and paste the contents of `Project 2.lean` into the `Main.lean` file in your project, or place `Project 2.lean` in the `./Lean/` directory and import it in `Main.lean`.

4. Build the project:
    ```bash
    lake build
    ```
