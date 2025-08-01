/-
Copyright (c) 2025 Francesco Nishanil Chotuck. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Francesco Nishanil Chotuck
-/


import Mathlib.Algebra.EuclideanDomain.Basic
import Mathlib.Algebra.EuclideanDomain.Field
import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Real.StarOrdered
import Mathlib.Topology.EMetricSpace.Paracompact

/-!
# Banach Fixed Point Theorem

In this file, we formalise the Banach Fixed Point Theorem
(also known as the Contraction Mapping Theorem) in the context of complete metric spaces.

## Main definitions

- `is_contraction`: A map `T : X → X` is a contraction if there exists `0 ≤ q < 1` such that
  `d(T(x), T(y)) ≤ q * d(x, y)` for all `x, y ∈ X`.
- `seq`: The sequence `{xₙ}` generated by iteratively applying the contraction: `xₙ = T(xₙ₋₁)`.

## Main results

- `contraction_inequality`: Recursive distance bound for the sequence.
- `seq_is_cauchy`: The `seq` sequence is Cauchy.
- `seq_converges`: The sequence converges to a limit in complete metric spaces.
- `exists_fixed_point`: Existence of a fixed point.
- `fixed_point_unique`: Uniqueness of the fixed point.
- `banach_fixed_point`: The Banach Fixed Point theorem.

## Notation

- `seq T x₀ n`: The n-th iterate of `T` starting at `x₀`.

## References

- [Banach1922] S. Banach, "Sur les opérations dans les ensembles abstraits et leurs applications aux
  équations intégrales", _Fundamenta Mathematicae_, 3, 133–181, 1922.
- [Lee2003] J. M. Lee, _Introduction to Smooth Manifolds_, Graduate Texts in Mathematics,
  Springer, 2003.
-/

section Definitions

/--
A function `T : X → X` is a contraction if there exists `0 ≤ q < 1` such that
`d(T(x),T(y)) ≤ q * d(x,y)` for all `x, y ∈ X`.
-/
def is_contraction {X : Type} [MetricSpace X] (T : X → X) (q : ℝ) : Prop :=
    0 ≤ q ∧ q < 1 ∧ ∀ x y : X, dist (T x) (T y) ≤ q * dist x y

/--
The sequence `{seq T x₀ n}` is defined by iteratively by `xₙ = T(xₙ₋₁)`
-/
def seq {X : Type} (T : X → X) (x₀ : X) : ℕ → X
    | 0       => x₀
    | (n + 1) => T (seq T x₀ n)

end Definitions

variable {X : Type} [MetricSpace X]

section Inequalities

open Finset

/--
For a sequence `x : ℕ → X` and `n ≤ m`,
`dist (x m) (x n)` is bounded by the sum of distances between consecutive terms:
`dist (x m) (x n) ≤ ∑ k in range (m - n), dist (x (n + k)) (x (n + k + 1))`
-/
lemma dist_seq_telescoping (x : ℕ → X) (m n : ℕ) (h : n ≤ m) :
    dist (x m) (x n)
      ≤ Finset.sum (range (m - n)) (fun k ↦ dist (x (n + k)) (x (n + k + 1))) := by
  -- Express `m` as `n + d`, where `d = m - n`
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le h
  induction' d with d hd -- Proceed by induction on `d`
  · -- Base case: when `d = 0`, we have `m = n`, so `dist(x n, x n) = 0`
    simp only [add_zero, dist_self, tsub_self, range_zero, sum_empty, le_refl]
  · -- Inductive step: Assume the result holds for `d`, prove it for `d + 1`
    simp only [add_tsub_cancel_left]
    -- Inductive hypothesis: The sum of distances up to `d` satisfies the inequality
    have ih' : dist (x (n + d)) (x n)
        ≤ Finset.sum (range d) (fun k ↦ dist (x (n + k)) (x (n + k + 1))) := by aesop
    calc
      -- Apply the triangle inequality to include `x(n + d)`
      dist (x (n + d.succ)) (x n)
          ≤ dist (x (n + d.succ)) (x (n + d)) + dist (x (n + d)) (x n) :=
            dist_triangle (x (n + d.succ)) (x (n + d)) (x n)
      -- Use the induction hypothesis to bound `dist(x(n + d), x n)`
      _ ≤ dist (x (n + d.succ)) (x (n + d))
          + Finset.sum (range d) (fun k ↦ dist (x (n + k)) (x (n + k + 1))) :=
            add_le_add (le_refl (dist (x (n + d.succ)) (x (n + d)))) ih'
      -- Rewriting to express the sum in terms of `range d.succ`
      _ = Finset.sum (range d.succ) (fun k ↦ dist (x (n + k)) (x (n + k + 1))) := by
        rw [add_comm, sum_range_succ, ← dist_comm (x (n + d)) (x (n + d.succ))]
        rfl

variable {T : X → X} {q : ℝ}

/--
For a contraction `T` with factor `q`, the sequence `{xₙ}` satisfies
`dist (xₙ₋₁, xₙ) ≤ qⁿ ⋅ dist (x₁, x₀)` for all `n ∈ ℕ`.
-/
lemma contraction_inequality (hT : is_contraction T q) (x₀ : X) :
    ∀ n : ℕ, dist (seq T x₀ (n + 1)) (seq T x₀ n) ≤ q ^ n * dist (seq T x₀ 1) x₀ := by
  intro n
  induction' n with k hk -- Perform induction on `n`
  · -- Base case: when `n = 0`, the inequality holds trivially
    simp only [seq, pow_zero, one_mul, le_refl]
  · -- Inductive case
    simp only [seq]
    -- Extract properties of the contraction mapping
    obtain ⟨h_q_nonneg, h_q_lt1, h_contraction⟩ := hT
    calc
      -- Expressing the distance between consecutive iterates
      dist (seq T x₀ (k + 2)) (seq T x₀ (k + 1))
      = dist (T (seq T x₀ (k + 1))) (T (seq T x₀ k)) := by rfl -- Definition of the sequence
      -- Apply the contraction property: `d(T(x), T(y)) ≤ q * d(x, y)`
      _ ≤ q * dist (seq T x₀ (k + 1)) (seq T x₀ k) := h_contraction (seq T x₀ (k + 1)) (seq T x₀ k)
      -- Use the induction hypothesis: `d(x_{k+1}, x_k) ≤ q^k * d(x₁, x₀)`
      _ ≤ q * (q ^ k * dist (seq T x₀ 1) x₀) := by exact mul_le_mul_of_nonneg_left hk h_q_nonneg
      -- Rewriting to group terms correctly
      _ ≤ (q * q ^ k) * dist (seq T x₀ 1) x₀ := by rw [mul_assoc]
      -- Using exponentiation property: `q * q^k = q^(k+1)`
      _ = q ^ (k + 1) * dist (seq T x₀ 1) x₀ := by rw [pow_succ']

/--
For a contraction `T`, the inequality
`dist (seq T x₀ m) (seq T x₀ n) ≤ q^n * dist (seq T x₀ 1) x₀ * ∑ i in range (m - n), q^i`
holds
-/
lemma seq_dist_geometric_sum_bound (hT : is_contraction T q) (x₀ : X) (m n : ℕ) (hmn : n ≤ m) :
    dist (seq T x₀ m) (seq T x₀ n)
      ≤ q ^ n * dist (seq T x₀ 1) x₀ * ∑ i in range (m - n), q ^ i := by
  -- Step 1: Establish an upper bound on the distance between `seq T x₀ m` and `seq T x₀ n`
  have hBound : dist (seq T x₀ m) (seq T x₀ n)
    ≤ ∑ i in range (m - n), q ^ (n + i) * dist (seq T x₀ 1) x₀ := by
    -- Apply the telescoping distance inequality
    apply (dist_seq_telescoping (seq T x₀) m n hmn).trans
    -- Show that summing over distances preserves the inequality
    apply sum_le_sum
    intro i _
    -- Rewrite the distance using symmetry
    rw [dist_comm]
    -- Apply the contraction inequality to bound each term
    exact contraction_inequality hT x₀ (n + i)
  -- Apply the contraction inequality to bound each term
  calc
    -- Use the previously established bound
    dist (seq T x₀ m) (seq T x₀ n)
      ≤ ∑ i in range (m - n), q ^ (n + i) * dist (seq T x₀ 1) x₀ := hBound
    -- Rewrite the exponentiation using the property `q^(n + i) = q ^ n * q^i`
    _ = ∑ i in range (m - n), (q ^ n * q ^ i) * dist (seq T x₀ 1) x₀ := by
            simp only [pow_add, mul_assoc]
    -- Factor out `q ^ n * dist (seq T x₀ 1) x₀` from each term in the sum
    _ = ∑ i in range (m - n), (q ^ n * dist (seq T x₀ 1) x₀) * q ^ i := by
            apply sum_congr rfl
            intro i hi
            nth_rewrite 4 [mul_comm] -- Reorder multiplication
            rw [mul_comm, mul_assoc]
    -- Factor `q ^ n * dist (seq T x₀ 1) x₀` out of the entire sum
    _ = q ^ n * dist (seq T x₀ 1) x₀ * ∑ i in range (m - n), q ^ i :=
          by rw [mul_sum]

/--
For `0 ≤ q < 1`,
the partial geometric sum is bounded above by the infinite sum.
-/
lemma partial_sum_le_infinite_sum (hq0 : 0 ≤ q) (hq1 : q < 1) (m n : ℕ) :
    ∑ k in range (m - n), q ^ k ≤ ∑' k, q ^ k := by
  by_cases h : n ≤ m
  -- Case 1: `n ≤ m`, so `(m - n)` is nonnegative
  · have h_nonneg : ∀ k, 0 ≤ q ^ k := fun k ↦ pow_nonneg hq0 k
    -- Apply the standard inequality: finite sum is bounded by the infinite sum
    refine sum_le_tsum (range (m - n)) (fun i a ↦ h_nonneg i) ?_
    -- Shows that the geometric series `∑' q^k` is summable
    exact summable_geometric_of_lt_one hq0 hq1
  · -- Case 2: `n > m`, so `(m - n)` is negative (empty sum)
    refine sum_le_tsum (range (m - n)) ?_ ?_
    -- Shows that each term in the finite sum is nonnegative
    exact fun i a ↦ pow_nonneg hq0 i
    -- Shows that the infinite geometric series is summable
    exact summable_geometric_of_lt_one hq0 hq1

/--
For a contraction `T`,
`dist (seq T x₀ m) (seq T x₀ n) ≤ q^n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹`
Bounding the distance using a geometric series sum.
-/
lemma seq_dist_bound_simplified (hT : is_contraction T q) (x₀ : X) (m n : ℕ) (hmn : n ≤ m) :
    dist (seq T x₀ m) (seq T x₀ n) ≤ q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ := by
  -- Step 1: Use the previously established bound on the sequence distance
  have h1 := seq_dist_geometric_sum_bound hT x₀ m n hmn
  -- Step 2: The partial sum of the geometric series is bounded above by the infinite sum
  have h2 : ∑ i in range (m - n), q ^ i ≤ ∑' i, q ^ i :=
    partial_sum_le_infinite_sum hT.1 hT.2.1 m n
  -- Step 3: The closed-form sum of the infinite geometric series
  have h3 : ∑' i, q ^ i = (1 - q)⁻¹ :=
    tsum_geometric_of_lt_one hT.1 hT.2.1
  -- Step 4: Applying the inequalities to obtain the final bound
  calc
    dist (seq T x₀ m) (seq T x₀ n)
        ≤ q ^ n * dist (seq T x₀ 1) x₀ * ∑ i in range (m - n), q ^ i := h1
    -- Use the upper bound on the partial sum
    _ ≤ q ^ n * dist (seq T x₀ 1) x₀ * ∑' i, q ^ i := by
      apply mul_le_mul_of_nonneg_left h2
      -- Show that `q ^ n * d(x₁, x₀)` is nonnegative
      apply mul_nonneg
      · exact pow_nonneg hT.1 n
      · exact dist_nonneg
    _ = q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ := by rw [h3]

/--
We have `0 < 1 - q` since `q < 1`.
-/
lemma one_minus_q_pos (hT : is_contraction T q) :
    0 < 1 - q := by
  -- Extract the fact that `q < 1` from the contraction property
  have hq_lt1 := hT.2.1
  -- Rearrange to show that `1 - q` is positive
  exact sub_pos.mpr hq_lt1

/--
For a contraction `T`, if
`q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ < ε,`
then either `dist (seq T x₀ 1) x₀ = 0` or
`q ^ n < ε * (1 - q) * (dist (seq T x₀ 1) x₀)⁻¹.`
-/
lemma rearrangement_seq_final (hT : is_contraction T q) (x₀ : X) (n : ℕ) (ε : ℝ)
    (h : q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ < ε) :
    (dist (seq T x₀ 1) x₀ = 0 ∨ q ^ n < ε * (1 - q) * (dist (seq T x₀ 1) x₀)⁻¹) := by
  by_cases hd : x₀ = seq T x₀ 1
  · left
    simp only [dist_eq_zero]
    exact (Eq.symm hd)
  · right
    have h_d_pos : 0 < dist (seq T x₀ 1) x₀ := dist_pos.mpr fun a ↦ hd ((Eq.symm a))
    have h_1q_pos : 0 < 1 - q := one_minus_q_pos hT
    rw [propext (lt_mul_inv_iff₀ h_d_pos)]
    nth_rewrite 2 [mul_comm]
    rw [← propext (mul_inv_lt_iff₀' h_1q_pos)]
    exact h

/-
If `⌈a⌉₊ + 1 ≤ n`, then `a < n`
-/
lemma ceil_add_one_le_nat_imp_lt (a : ℝ) (n : ℕ) : ⌈a⌉₊ + 1 ≤ n → a < n := by
  intro h
  -- By definition of ceiling, we have `a ≤ ⌈a⌉₊`
  have h1 : a ≤ ⌈a⌉₊ := Nat.le_ceil a
  -- From the hypothesis, we get` ⌈a⌉₊ < n` by subtracting one
  -- and using the fact that the ceiling is a natural number
  have h2 : (⌈a⌉₊ : ℝ) < n := Nat.cast_lt.mpr (Nat.lt_of_add_one_le h)
  -- Combining the two inequalities, we get `a < n`
  exact lt_of_le_of_lt h1 h2

end Inequalities

section Cauchy

variable {T : X → X} {q : ℝ}

/--
For a contraction `T`, the sequence `seq T x₀` is Cauchy.
-/
theorem seq_is_cauchy (hT : is_contraction T q) (x₀ : X) (hq : 0 < q) : CauchySeq (seq T x₀) := by
  -- Rewrite the Cauchy sequence definition in metric spaces
  rw [Metric.cauchySeq_iff]
  intro ε hε
  -- `q < 1` from the contraction property
  have q_lt1 := hT.2.1
  have h_one_minus_q_pos : 0 < 1 - q := one_minus_q_pos hT
  -- Define `N` such that the geometric term is sufficiently small
  set N := ⌈(Real.log ((ε * (1 - q)) / dist (seq T x₀ 1) x₀)) / Real.log q⌉₊ + 1 with hN
  use N
  intro m hm n hn
  -- Without loss of generality, assume `n ≤ m`
  wlog hmn : n ≤ m generalizing m n
  · rw [dist_comm]
    exact this n hn m hm (le_of_not_le hmn)
  · -- Case 1: The sequence stabilizes if `x₀ = seq T x₀ 1`
    by_cases h_terms_eq : x₀ = seq T x₀ 1
    · have h_dist_eq0 : dist (seq T x₀ 1) x₀ = 0 := by
        simp only [dist_eq_zero]
        exact (Eq.symm h_terms_eq)
      calc
        _ ≤ q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ := seq_dist_bound_simplified hT x₀ m n hmn
        _ ≤ q ^ n * 0 * (1 - q)⁻¹ := by
          exact le_of_eq (congrFun (congrArg HMul.hMul
          (congrArg (HMul.hMul (q ^ n)) h_dist_eq0)) (1 - q)⁻¹)
        _ = 0 := by field_simp
        _ < ε := by exact hε
    · -- Case 2: Apply the geometric bound for contractions
      have h_d_pos : dist (seq T x₀ 1) x₀ > 0 := by
        exact dist_pos.mpr fun a ↦ h_terms_eq (Eq.symm a)
      have hN' : q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ < ε := by
        rw [hN] at hn
        simp only [ge_iff_le] at hn
        apply ceil_add_one_le_nat_imp_lt at hn
        rw [div_lt_iff_of_neg] at hn
        · rw [← Real.log_pow, Real.log_lt_iff_lt_exp] at hn
          · rw [Real.exp_log] at hn
            · rw [lt_div_iff₀] at hn
              · rw [← inv_mul_lt_iff₀'] at hn
                · rw [← mul_assoc] at hn
                  rw [mul_comm, ← mul_assoc]
                  exact hn
                · exact h_one_minus_q_pos
              · simp only [dist_pos, ne_eq]
                exact fun a ↦ h_terms_eq ((Eq.symm a))
            · positivity
          · positivity
        · exact Real.log_neg hq q_lt1
      calc
        dist (seq T x₀ m) (seq T x₀ n)
          ≤ q ^ n * dist (seq T x₀ 1) x₀ * (1 - q)⁻¹ := by
            exact seq_dist_bound_simplified hT x₀ m n hmn
          _ = q ^ n * (dist (seq T x₀ 1) x₀ * (1 - q)⁻¹) := by field_simp
          _ < ε * (1 - q) * (dist (seq T x₀ 1) x₀)⁻¹ * (dist (seq T x₀ 1) x₀ * (1 - q)⁻¹) := by
            gcongr
            have := rearrangement_seq_final hT _ _ _ hN'
            cases' this with h_left h_right
            · rw [h_left]
              aesop
            · exact h_right
          _ = ε := by field_simp

end Cauchy

section BanachFixedPoint

variable {T : X → X} {q : ℝ}

/--
A contraction mapping is continuous.
-/
lemma contraction_is_continuous (hT : is_contraction T q) :
    Continuous T := by
  rw [is_contraction] at hT
  rw [Metric.continuous_iff]
  intro b ε hε
  rcases hT with ⟨h_q_gt0, h_q_lt1, h_contraction⟩
  -- Case 1: If `q = 0`, the mapping is constant and thus continuous
  by_cases h_q_eq0 : q = 0
  · use ε
    constructor
    · exact hε
    · intro a h_dist_ε_1
      specialize h_contraction a b
      rw [h_q_eq0] at h_contraction
      subst h_q_eq0
      aesop
  -- Case 2: If `0 < q < 1`, use the contraction property to show continuity
  · use (ε / q)
    constructor
    · positivity
    · intro a h_dist_ε_2
      specialize h_contraction a b
      calc
      -- Apply the contraction property
        dist (T a) (T b) ≤ q * dist a b := h_contraction
        -- Scale the distance to show continuity
        _ < q * (ε / q) := by gcongr
        _ = ε := by field_simp [h_q_eq0]

/--
For a contraction `T` in a complete space, the sequence `seq T x₀` converges.
-/
lemma seq_converges (hT : is_contraction T q) (x₀ : X) [CompleteSpace X] :
    ∃ x', Filter.Tendsto (seq T x₀) Filter.atTop (nhds x') := by
  -- Case 1: If `q = 0`, the sequence is constant and converges to `T x₀`
  obtain rfl | hq := eq_or_lt_of_le hT.1
  · use T x₀
    -- Show that the sequence is eventually constant
    have : ∀ᶠ n in Filter.atTop, seq T x₀ n = T x₀ := by
      filter_upwards [Filter.eventually_gt_atTop 0] with n hn
      cases n with
      | zero => simp only [lt_self_iff_false] at hn
      | succ n =>
          rw [seq]
          apply eq_of_dist_eq_zero
          have h_contr := hT.2.2 (seq T x₀ n) (x₀)
          rw [zero_mul] at h_contr
          apply le_antisymm
          · exact h_contr
          · exact dist_nonneg
    -- Conclude that the sequence converges to the constant limit
    have : seq T x₀ =ᶠ[Filter.atTop] fun n ↦ T x₀ := this
    apply Filter.Tendsto.congr' this.symm
    simp only [tendsto_const_nhds_iff]
  -- Case 2: If `0 < q < 1`, the sequence is Cauchy
  have c : CauchySeq (seq T x₀) := seq_is_cauchy hT x₀ hq
  exact cauchySeq_tendsto_of_complete c

/--
If `seq T x₀` converges to `x'`, then `x'` is a fixed point.
-/
lemma limit_fixed (hT : is_contraction T q) (x₀ : X)
    {x' : X} (hx' : Filter.Tendsto (seq T x₀) Filter.atTop (nhds x')) : T x' = x' := by
  -- `T` is continuous
  have hc := contraction_is_continuous hT
  -- Applying continuity to the limit of the sequence
  have hlimT : Filter.Tendsto (T ∘ seq T x₀) Filter.atTop (nhds (T x')) :=
    Filter.Tendsto.comp (hc.tendsto x') hx'
  -- The sequence shifted by one step also converges to the same limit
  have hlimS : Filter.Tendsto (fun n ↦ seq T x₀ (n + 1)) Filter.atTop (nhds x') :=
    hx'.comp (Filter.tendsto_add_atTop_nat 1)
  -- Uniqueness of limits implies that `T x' = x'`
  exact tendsto_nhds_unique hlimT hlimS

/--
For a contraction `T` in a complete space, there exists a fixed point `x'`.
-/
theorem exists_fixed_point (hT : is_contraction T q) (x₀ : X) [CompleteSpace X] :
    ∃ x' : X, T x' = x' := by
  -- The sequence generated by the contraction converges
  obtain ⟨x', hx'⟩ := seq_converges hT x₀
  -- The limit of the sequence is a fixed point
  exact ⟨x', limit_fixed hT x₀ hx'⟩

/--
A contraction mapping has a unique fixed point.
-/
theorem contraction_fixed_point_unique (hT : is_contraction T q) (x y : X)
  (hx : T x = x) (hy : T y = y) :
    x = y := by
  -- Apply the contraction property to the fixed points
  have h_contr := hT.2.2
  have h_dist : dist (T x) (T y) ≤ q * dist x y := h_contr x y
  -- Use the fixed point properties to simplify the distance
  rw [hx, hy] at h_dist
  -- Since `q < 1`, we have `0 < 1 - q`
  have h_one_minus_q_pos : 0 < 1 - q := one_minus_q_pos hT
  -- Multiply both sides by `1 - q` and conclude that the distance is zero
  have h_zero : (1 - q) * dist x y ≤ 0 := by linarith
  have h_dist_zero : dist x y = 0 := by
    apply le_antisymm
    · exact nonpos_of_mul_nonpos_right h_zero h_one_minus_q_pos
    · apply dist_nonneg
  -- Conclude that the fixed points are equal
  exact eq_of_dist_eq_zero h_dist_zero

/--
A contraction mapping on a complete metric space has a unique fixed point.
-/
theorem banach_fixed_point (hT : is_contraction T q) (x₀ : X) [CompleteSpace X] :
    ∃! x : X, T x = x := by
  -- Obtain an approximate fixed point `x'` using the existence theorem
  obtain ⟨x', hT_x'⟩ := exists_fixed_point hT x₀
  use x' -- Declare `x'` as the unique fixed point
  constructor -- Prove both existence and uniqueness
  ·  -- First, showing that `x'` is indeed a fixed point
    exact hT_x'
  · -- Next, proving uniqueness
    intro x hx
    -- Using the uniqueness result for contraction mappings
    exact Eq.symm (contraction_fixed_point_unique hT x' x hT_x' hx)

end BanachFixedPoint

#lint
#min_imports
