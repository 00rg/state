pub struct Farewell {
    subject: String,
}

impl Farewell {
    pub fn new(subject: &str) -> Farewell {
        Farewell { subject: subject.to_owned() }
    }

    pub fn say(&self) -> String {
        let v: u8 = rand::random();
        format!("Goodbye, {} ({})!", self.subject, v)
    }
}
