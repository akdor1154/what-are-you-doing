use std::io::{Read, Write};

fn read() {
	let res = std::fs::File::open(TMP_PATH);
	let mut f = match res {
		Err(e) if e.kind() == std::io::ErrorKind::NotFound => return,
		Err(e) => Err(e).unwrap(),
		Ok(f) => f,
	};
	let mut buf = String::new();
	f.read_to_string(&mut buf).unwrap();
	std::io::stdout().write(buf.as_bytes()).unwrap();
}

fn clear() {
	match std::fs::remove_file(TMP_PATH) {
		Ok(_) => (),
		Err(e) if e.kind() == std::io::ErrorKind::NotFound => (),
		Err(e) => Err(e).unwrap(),
	}
}

fn write_file(path: &str, contents: &str) {
	let mut file = std::fs::File::create(path).unwrap();
	file.write(contents.as_bytes()).unwrap();
}

const TMP_PATH: &str = "/tmp/what-are-you-working-on";

fn ask() {
	let ans_bytes = std::process::Command::new("zenity")
		.args(["--entry", "--text", "What are you working on?"])
		.output()
		.unwrap()
		.stdout;
	let ans = std::str::from_utf8(&ans_bytes).unwrap();
	write_file(TMP_PATH, ans)
}

#[derive(Clone, PartialEq, Eq, clap::ValueEnum)]
enum Event {
	#[clap(name("SESSION_START"))]
	Start,
	#[clap(name("SESSION_INTERRUPT"))]
	Interrupt,
	#[clap(name("SESSION_COMPLETE"))]
	Complete,
}

#[derive(Clone, PartialEq, Eq, clap::ValueEnum)]
enum SessionType {
	#[clap(name("POMODORO"))]
	Pomodoro,
	#[clap(name("SHORT_BREAK"))]
	ShortBreak,
	#[clap(name("LONG_BREAK"))]
	LongBreak,
}

#[derive(Clone, PartialEq, Eq, clap::ValueEnum, Debug)]
enum Action {
	Ask,
	Clear,
	Read,
}

fn main() {
	let matches = clap::Command::new("what-are-you-doing")
		.arg(
			clap::arg!(--event[EVENT])
				.ignore_case(true)
				.value_parser(clap::value_parser!(Event)),
		)
		.arg(
			clap::arg!(--"session-type"[SESSION_TYPE])
				.ignore_case(true)
				.value_parser(clap::value_parser!(SessionType)),
		)
		.arg(
			clap::arg!([ACTION])
				.value_parser(clap::value_parser!(Action))
				.ignore_case(true),
		)
		.get_matches();

	let action_from_arg = matches.get_one::<Action>("ACTION");
	let action_from_event_and_session = {
		let event = matches.get_one::<Event>("event");
		let session_type = matches.get_one::<SessionType>("session-type");
		match (event, session_type, action_from_arg) {
			(Some(Event::Start), Some(SessionType::Pomodoro), _) => Some(Action::Ask),
			(Some(Event::Interrupt), Some(SessionType::Pomodoro), _) => Some(Action::Clear),
			(Some(Event::Complete), Some(SessionType::Pomodoro), _) => Some(Action::Clear),
			(Some(_), Some(_), _) => None,
			(None, None, Some(_)) => None,
			(None, None, None) => panic!("you need one of action or event/session"),
			(_, _, _) => panic!("If using --event and --session-type, you must pass both"),
		}
	};
	let action = match (action_from_arg, action_from_event_and_session) {
		(Some(a), None) => Some(a.to_owned()),
		(None, Some(a)) => Some(a),
		(Some(_a), Some(_b)) => panic!("you can pass only one of action or event/session"),
		(None, None) => None,
	};

	match action {
		Some(Action::Ask) => ask(),
		Some(Action::Read) => read(),
		Some(Action::Clear) => clear(),
		None => (),
	}
}
