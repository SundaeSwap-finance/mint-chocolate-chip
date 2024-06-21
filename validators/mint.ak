use aiken/transaction.{ScriptContext, Mint, OutputReference, Input, Output, TransactionId, NoDatum}
use aiken/transaction/credential.{VerificationKeyCredential, Address}
use aiken/transaction/value.{PolicyId, MintedValue}
use aiken/list
use aiken/dict

validator(utxo_ref: OutputReference) {
    pub fn mint(_r: Data, ctx: ScriptContext) {
        expect Mint(own_policy_id) = ctx.purpose
        mint_logic(own_policy_id, utxo_ref, ctx.transaction.inputs, ctx.transaction.mint)
    }
}

fn mint_logic(
    own_policy_id: PolicyId,
    utxo_ref: OutputReference,
    inputs: List<Input>,
    mint: MintedValue
) -> Bool {
    let utxo_spent = inputs
        |> list.any(fn(i) { i.output_reference == utxo_ref })
    let only_burns = mint
        |> value.from_minted_value()
        |> value.tokens(own_policy_id)
        |> dict.to_pairs()
        |> list.all(fn(Pair(_, qty)) { qty < 0 })

    or {
        utxo_spent,
        only_burns
    }
}

fn inputs(utxo_ref: OutputReference) -> List<Input> {
    [
        Input(utxo_ref, Output {
            address: Address {
                payment_credential: VerificationKeyCredential(#"abcd"),
                stake_credential: None
            },
            value: value.from_lovelace(1),
            datum: NoDatum,
            reference_script: None,
        })
    ]
}

test can_mint() {
    let own_policy_id = #"ab"
    let utxo_ref = OutputReference(TransactionId(#"bc"), 0)
    let inputs = inputs(utxo_ref)
    let minted_value = [Pair(own_policy_id, [Pair(#"", 1)])]
        |> value.from_asset_list()
        |> value.to_minted_value()
    mint_logic(own_policy_id, utxo_ref, inputs, minted_value)
}

test can_mint_multiple() {
    let own_policy_id = #"ab"
    let utxo_ref = OutputReference(TransactionId(#"bc"), 0)
    let inputs = inputs(utxo_ref)
    let minted_value = [Pair(own_policy_id, [Pair(#"", 1), Pair(#"abcd", 3)])]
        |> value.from_asset_list()
        |> value.to_minted_value()
    mint_logic(own_policy_id, utxo_ref, inputs, minted_value)
}

test can_burn() {
    let own_policy_id = #"ab"
    let utxo_ref = OutputReference(TransactionId(#"bc"), 0)
    let inputs = inputs(OutputReference(TransactionId("#de"), 1))
    let minted_value = [Pair(own_policy_id, [Pair(#"", -1), Pair(#"abcd", -3)])]
        |> value.from_asset_list()
        |> value.to_minted_value()
    mint_logic(own_policy_id, utxo_ref, inputs, minted_value)
}

test cant_double_mint() fail {
    let own_policy_id = #"ab"
    let utxo_ref = OutputReference(TransactionId(#"bc"), 0)
    let inputs = inputs(OutputReference(TransactionId("#de"), 1))
    let minted_value = [Pair(own_policy_id, [Pair(#"", 1), Pair(#"abcd", 3)])]
        |> value.from_asset_list()
        |> value.to_minted_value()
    mint_logic(own_policy_id, utxo_ref, inputs, minted_value)
}