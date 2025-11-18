use anyhow::{Result, anyhow};
use flutter_rust_bridge::frb;
use serde::Serialize;

use tokenizers::{Tokenizer, TruncationDirection, TruncationParams, TruncationStrategy};

//
// Returned to Dart
//
#[derive(Debug, Clone, Serialize)]
pub struct TokenData {
    pub input_ids: Vec<i64>,
    pub attention_mask: Vec<i64>,
    pub length: i32,
}

const PAD_TOKEN_ID: i64 = 1;  // <pad> from your config


//
// State (handle) stored by FRB
//
pub struct TokenizerHandle {
    tok: Tokenizer,
    pub max_length: usize,
}

//
// Load tokenizer.json from path
//
pub fn load_tokenizer(path: String, max_length: usize) -> Result<TokenizerHandle> {
    let mut tokenizer =
        Tokenizer::from_file(&path).map_err(|e| anyhow!("Failed to load tokenizer: {:?}", e))?;

    // Enable built-in truncation inside tokenizers
    tokenizer
        .with_truncation(Some(TruncationParams {
            direction: TruncationDirection::Right,
            max_length,
            stride: 0,
            strategy: TruncationStrategy::LongestFirst,
        }))
        .map_err(|e| anyhow!("Failed to set truncation params: {:?}", e))?;

    Ok(TokenizerHandle {
        tok: tokenizer,
        max_length,
    })
}

//
// Update max_length dynamically (also updates tokenizer’s truncation)
//
pub fn set_max_length(handle: &mut TokenizerHandle, max_len: usize) -> Result<()> {
    if max_len == 0 {
        return Err(anyhow!("max_length must be > 0"));
    }

    handle.max_length = max_len;

    handle
        .tok
        .with_truncation(Some(TruncationParams {
            direction: TruncationDirection::Right,
            max_length: max_len,
            stride: 0,
            strategy: TruncationStrategy::LongestFirst,
        }))
        .map_err(|e| anyhow!("Failed to update truncation: {:?}", e))?;

    Ok(())
}

//
// Tokenize a single string
//
pub fn tokenize(handle: &TokenizerHandle, text: String) -> Result<TokenData> {
    let encoding = handle.tok.encode(text, false)
        .map_err(|e| anyhow!("Tokenization failed: {:?}", e))?;

    let mut ids: Vec<i64> = encoding.get_ids().iter().map(|&x| x as i64).collect();
    let actual_length = ids.len().min(handle.max_length);

    // Truncate if needed
    ids.truncate(handle.max_length);

    // Pad to max_length
    let mut attention_mask = vec![1i64; actual_length];
    while ids.len() < handle.max_length {
        ids.push(PAD_TOKEN_ID);
        attention_mask.push(0);
    }

    Ok(TokenData {
        input_ids: ids,
        attention_mask,
        length: actual_length as i32,
    })
}
//
// Tokenize a batch of strings
//
pub fn tokenize_batch(handle: &TokenizerHandle, texts: Vec<String>) -> Result<Vec<TokenData>> {
    let mut out = Vec::with_capacity(texts.len());

    for t in texts {
        let encoding = handle
            .tok
            .encode(t, false)
            .map_err(|e| anyhow!("Batch tokenization failed: {:?}", e))?;

        let mut ids: Vec<i64> = encoding.get_ids().iter().map(|&x| x as i64).collect();
        let actual_length = ids.len().min(handle.max_length);

        // Truncate if needed
        ids.truncate(handle.max_length);

        // Pad to max_length
        let mut attention_mask = vec![1i64; actual_length];
        while ids.len() < handle.max_length {
            ids.push(PAD_TOKEN_ID);
            attention_mask.push(0);
        }

        out.push(TokenData {
            input_ids: ids,
            attention_mask,
            length: actual_length as i32,
        });
    }

    Ok(out)
}