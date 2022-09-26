#!/usr/bin/env ocaml

#load "unix.cma"

open Format;;

let dump_list f (l:string list) = 
  Format.fprintf f "%s" (String.concat "," l)

let channel_to_seq (ch:in_channel) = 
  let rec lines_seq = (
    fun () ->
      try
        let next_line = input_line ch in
        Seq.Cons (next_line, lines_seq)
      with End_of_file ->
        close_in ch;
        Seq.Nil
  ) in
  lines_seq


let _run (arg0: string) (argv:string list) : string = 
  let output_channel = Unix.open_process_args_in arg0 (Array.of_list argv) in
  let lines_seq = channel_to_seq output_channel in
  let output_joined = String.concat "\n" (List.of_seq lines_seq) in
  output_joined
;;

let run (cmd:string list) : string = 
  match cmd with
  | [] -> raise (Invalid_argument "Need at least one arg!")
  | cmd -> _run "/usr/bin/env" ("/usr/bin/env"::cmd)
;;

let write_file (path:string) (str:string) =
  let file = open_out path in
    Printf.fprintf file "%s" str;
    close_out file
;;

let read_file (path:string) = 
  let file = open_in path in
  let lines = channel_to_seq file in
  String.concat "\n" (List.of_seq lines)

let tmp_path = "/tmp/what-are-you-working-on";;

let ask () =
  let ans = run ["zenity"; "--entry"; "--text"; "What are you working on?"] in
  write_file tmp_path ans;
  printf "%s\n" ans;
;;

let clear () = 
  Sys.remove tmp_path

let read () = 
  printf "%s\n" (read_file tmp_path)

type action =
  | Ask
  | Clear
  | Read
;;

type event = 
  | Start
  | Interrupt
  | Complete

type session_type =
  | Pomodoro
  | Break

let main () = 
  let usage_msg = "what-are-you-working-on ask|clear|[read]" in
  let event_ref = ref None in
  let session_type_ref = ref None in
  let action_ref = ref None in  let get_action str =
    let parsed = 
      match str with
      | "ask" -> Ask
      | "clear" -> Clear
      | "read" -> Read
      | other -> failwith (sprintf "Unknown action %s, need ask | clear | read." other) in
      action_ref := Some(parsed) in
  let set_event s = 
    event_ref := match s with
      | "SESSION_START" -> Some(Start)
      | "SESSION_INTERRUPT" -> Some(Interrupt)
      | "SESSION_END" -> Some(Complete)
      | _ -> failwith "Invalid event." in
    
  let set_session_type s =
    session_type_ref := match s with
      | "POMODORO" -> Some(Pomodoro)
      | "LONG_BREAK" -> Some(Break)
      | "SHORT_BREAK" -> Some(Break)
      | _ -> failwith "Invalid session type." in

  let speclist = [
    ("--event", Arg.Symbol (["SESSION_START"; "SESSION_INTERRUPT"; "SESSION_END"], set_event), "Event type" );
    ("--session-type", Arg.Symbol (["POMODORO"; "LONG_BREAK"; "SHORT_BREAK"], set_session_type), "Session type") 
  ] in
  Arg.parse speclist get_action usage_msg;

  let action_from_event_and_session = match event_ref.contents, session_type_ref.contents with
    | Some(Start), Some(Pomodoro) -> Some(Ask)
    | Some(Interrupt), Some(Pomodoro) -> Some(Clear)
    | Some(Complete), Some(Pomodoro) -> Some(Clear)
    | Some(_), Some(_) -> None (* break *)
    | None, None -> None
    | _, _ -> failwith ("If using --event and --session type, you must pass both") in
  
  let action_from_arg = action_ref.contents in

  let action = match action_from_arg, action_from_event_and_session with
    | Some(a), None -> a
    | None, Some(a) -> a
    | Some(a), Some(b) -> failwith "You can pass only one of action or event+session."
    | None, None -> Read in

  match action with
  | Read -> read ()
  | Ask -> ask ()
  | Clear -> clear ()
;;

main () ;;
