use flutter_rust_bridge_macros::frb;
use anyhow::{Result, anyhow};
use tokenizers::Tokenizer;

//
// A struct returned to Dart
//
#[frb]
pub struct TokenData {
    pub input_ids: Vec<i64>,
    pub attention_mask: Vec<i64>,
    pub length: i32,
}

//
// Handle for the loaded tokenizer
//
pub struct TokenizerHandle {
    tok: Tokenizer,
    max_length: usize,
}

//
// Load tokenizer.json
//
#[frb(sync)]
pub fn load_tokenizer(path: String) -> Result<TokenizerHandle> {
    let tok = Tokenizer::from_file(&path)
        .map_err(|e| anyhow!("Failed to load tokenizer {}: {:?}", path, e))?;

    // Default max_length is 1024 (safe + mobile friendly)
    Ok(TokenizerHandle { tok, max_length: 1024 })
}

//
// Change max_length (optional)
//
#[frb(sync)]
pub fn set_max_length(handle: &mut TokenizerHandle, max_len: i32) -> Result<()> {
    if max_len <= 0 {
        return Err(anyhow!("max_length must be > 0"));
    }
    handle.max_length = max_len as usize;
    Ok(())
}

//
// Encode a single text -> input_ids + mask
//
#[frb(sync)]
pub fn tokenize(handle: &TokenizerHandle, text: String) -> Result<TokenData> {
    let enc = handle
        .tok
        .encode(text, false)
        .map_err(|e| anyhow!("Tokenization failed: {:?}", e))?;

    let mut ids: Vec<i64> = enc.get_ids().iter().map(|x| *x as i64).collect();

    // Truncate based on max_length
    if ids.len() > handle.max_length {
        ids.truncate(handle.max_length);
    }

    // Mask is always 1 for each token
    let mask = vec![1_i64; ids.len()];

    Ok(TokenData {
        length: ids.len() as i32,
        input_ids: ids,
        attention_mask: mask,
    })
}

//
// Batch tokenization
//
#[frb(sync)]
pub fn tokenize_batch(handle: &TokenizerHandle, texts: Vec<String>) -> Result<Vec<TokenData>> {
    let mut results = Vec::with_capacity(texts.len());

    for t in texts {
        let enc = handle
            .tok
            .encode(t, false)
            .map_err(|e| anyhow!("Batch tokenization failed: {:?}", e))?;

        let mut ids: Vec<i64> = enc.get_ids().iter().map(|x| *x as i64).collect();

        if ids.len() > handle.max_length {
            ids.truncate(handle.max_length);
        }

        let mask = vec![1_i64; ids.len()];

        results.push(TokenData {
            length: ids.len() as i32,
            input_ids: ids,
            attention_mask: mask,
        });
    }

    Ok(results)
}
