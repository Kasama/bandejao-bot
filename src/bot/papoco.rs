use rand::Rng;

pub fn generate_papoco() -> Vec<(String, u64)> {
    let mut shots = 11;
    let mut rng = rand::thread_rng();

    let boom = if rng.gen::<f64>() > 0.9 {
        "..."
    } else {
        "POOOW"
    };

    let mut ret = vec![];

    while shots > 0 {
        let num = rng.gen_range(1..=shots);
        shots -= num;
        ret.push(("pra ".repeat(num), if shots == 0 { 1200 } else { 100 }))
    }

    ret.push((boom.to_owned(), 100));

    ret
}
