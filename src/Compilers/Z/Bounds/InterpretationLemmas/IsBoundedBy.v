Require Import Coq.ZArith.ZArith.
Require Import Coq.micromega.Psatz.
Require Import Crypto.Compilers.Z.Syntax.
Require Import Crypto.Compilers.Z.Syntax.Util.
Require Import Crypto.Compilers.Syntax.
Require Import Crypto.Compilers.Z.Bounds.Interpretation.
Require Import Crypto.Compilers.Z.Bounds.InterpretationLemmas.Tactics.
Require Import Crypto.Compilers.SmartMap.
Require Import Crypto.Util.ZUtil.
Require Import Crypto.Util.Bool.
Require Import Crypto.Util.FixedWordSizesEquality.
Require Import Crypto.Util.Tactics.DestructHead.

Local Open Scope Z_scope.

Local Arguments Bounds.is_bounded_by' !_ _ _ / .

Lemma is_bounded_by_truncation_bounds Tout bs v
      (H : Bounds.is_bounded_by (T:=Tbase TZ) bs v)
  : Bounds.is_bounded_by (T:=Tbase Tout)
                         (Bounds.truncation_bounds (Bounds.bit_width_of_base_type Tout) bs)
                         (ZToInterp v).
Proof.
  destruct bs as [l u]; cbv [Bounds.truncation_bounds Bounds.is_bounded_by Bounds.is_bounded_by' Bounds.bit_width_of_base_type Bounds.log_bit_width_of_base_type option_map ZRange.is_bounded_by'] in *; simpl in *.
  repeat first [ break_t_step
               | fin_t
               | progress simpl in *
               | Zarith_t_step
               | rewriter_t
               | word_arith_t ].
Qed.

Local Arguments N.ldiff : simpl never.
Lemma land_abs_bounds a b
  : a < 0 \/ b < 0
    -> -(2^(Z.log2_up (Z.max (Z.abs a) (Z.abs b))))
       <= Z.land a b
       <= Z.max a b.
Proof.
  destruct a, b; simpl Z.abs; split;
    try solve [ unfold Z.max; simpl; lia
              | unfold Z.max; simpl; apply Z.opp_nonpos_nonneg; auto with zarith
              | match goal with
                | [ |- - _ <= _ ]
                  => transitivity 0;
                     solve [ unfold Z.max; simpl; lia
                           | unfold Z.max; simpl; apply Z.opp_nonpos_nonneg; auto with zarith ]
                | [ |- Z.land (Z.pos _) (Z.pos _) <= Z.max _ _ ]
                  => apply Z.max_case_strong; intro;
                     first [ apply Z.land_upper_bound_l
                           | apply Z.land_upper_bound_r ];
                     lia
                end ].
  all:simpl.
  all:admit.
Admitted.
Local Existing Instances Z.add_le_Proper Z.log2_up_le_Proper Z.pow_Zpos_le_Proper Z.sub_le_eq_Proper.
Lemma lor_abs_bounds a b
  : a < 0 \/ b < 0
    -> Z.min a b
       <= Z.lor a b
       <= 2^(Z.log2_up (Z.max (Z.abs a) (Z.abs b) + 1)) - 1.
Proof.
  destruct a, b; simpl Z.abs; split;
    try solve [ unfold Z.max, Z.min; simpl; lia
              | unfold Z.max, Z.min; simpl; apply Z.opp_nonpos_nonneg; auto with zarith
              | match goal with
                | [ |- Z.min (Z.pos _) (Z.pos _) <= Z.lor _ _ ]
                  => apply Z.lor_bounds_gen_lower; lia
                end
              | apply Z.lor_bounds_upper ];
    repeat first [ rewrite Z.max_r by lia
                 | rewrite Z.max_l by lia
                 | rewrite Z.lor_0_l
                 | rewrite Z.lor_0_r
                 | omega
                 | lia
                 | rewrite <- Z.log2_up_le_full; lia ].
Admitted.

Local Arguments Z.pow : simpl never.
Local Arguments Z.add !_ !_.
Local Existing Instances Z.add_le_Proper Z.log2_up_le_Proper Z.pow_Zpos_le_Proper Z.sub_le_eq_Proper.
Lemma is_bounded_by_interp_op t tR (opc : op t tR)
      (bs : interp_flat_type Bounds.interp_base_type _)
      (v : interp_flat_type interp_base_type _)
      (H : Bounds.is_bounded_by bs v)
  : Bounds.is_bounded_by (Bounds.interp_op opc bs) (Syntax.interp_op _ _ opc v).
Proof.
  destruct opc; apply is_bounded_by_truncation_bounds;
    repeat first [ progress simpl in *
                 | progress cbv [interp_op lift_op cast_const Bounds.interp_base_type Bounds.is_bounded_by' ZRange.is_bounded_by'] in *
                 | progress destruct_head'_prod
                 | progress destruct_head'_and
                 | omega
                 | match goal with
                   | [ |- context[interpToZ ?x] ]
                     => generalize dependent (interpToZ x); clear x; intros
                   | [ |- _ /\ True ] => split; [ | tauto ]
                   end ].
  { handle_four_corners. }
  { handle_four_corners. }
  { handle_four_corners. }
  { destruct_head Bounds.t.
    case_Zvar_nonneg; replace_all_neg_with_pos; handle_shift_neg;
      preprocess_shift_min_max.
    16:split_min_max; saturate_with_shift_facts; omega.
    all:admit. }
  { destruct_head Bounds.t.
    case_Zvar_nonneg; replace_all_neg_with_pos; handle_shift_neg;
      preprocess_shift_min_max.
    16:split_min_max; saturate_with_shift_facts; omega.
    all:admit. }
  { repeat first [ progress destruct_head Bounds.t
                 | progress simpl in *
                 | break_t_step
                 | Zarith_t_step
                 | rewriter_t
                 | progress replace_all_neg_with_pos
                 | progress saturate_land_lor_facts
                 | split_min_max; omega ].
    all:admit. }
  { repeat first [ progress destruct_head Bounds.t
                 | progress simpl in *
                 | break_t_step
                 | Zarith_t_step
                 | rewriter_t
                 | progress replace_all_neg_with_pos
                 | progress saturate_land_lor_facts
                 | progress Zarith_land_lor_t_step
                 | solve [ split_min_max; try omega; try Zarith_land_lor_t_step ] ].
    all:admit. }
  { repeat first [ progress destruct_head Bounds.t
                 | progress simpl in *
                 | progress split_min_max
                 | omega ]. }
Admitted.
