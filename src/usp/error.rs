use std::fmt::{Debug, Display};

#[derive(Debug)]
struct Error<D>
where
    D: Display + Debug,
{
    reason: D,
}

impl<D: Display + Debug> std::error::Error for Error<D> {}

impl<D: Display + Debug> Display for Error<D> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        Display::fmt(&self.reason, f)
    }
}

impl<D: Display + Debug> Error<D> {
    pub fn new(reason: D) -> Error<D>
    where
        D: Display + Debug,
    {
        Error { reason }
    }
}
