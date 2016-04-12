(* Semantic checking for the MicroC compiler *)

open Ast

module StringMap = Map.Make(String)
(* module SS = Set.Make(String) *)
(* Semantic checking of a program. Returns void if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)
let symbols = Hashtbl.create 1;;

(* let pic_attrs = List.fold_right SS.add ["h"; "w"; "bpp"; "data"] SS.empty;; *)
let pic_attrs = List.fold_left (fun m (t, n) -> StringMap.add n t m)
                StringMap.empty ([(Int, "h"); (Int, "w"); (Int, "bpp"); (Void, "data")])


let check program =
  (* Split program into gloabls & functions *)
  let rec transform p v f =
  match p with
  a::b -> (match a with
     Vdecl(x) -> transform b (x::v) f
     | Fdecl(x) -> transform b v (x::f))
  | [] -> (v,f)
  in
  let (globals, functions) = transform program [] [] 
  in
  let rec transform_globals g r =
  match g with
    a::b -> (
        match a with
        Bind(x) -> transform_globals b (x::r)
        | _ -> transform_globals b r
      )
    | [] -> r
  in let globals = transform_globals globals [] in

  (* Raise an exception if the given list has a duplicate *)
  let report_duplicate exceptf list =
    let rec helper = function
	     n1 :: n2 :: _ when n1 = n2 -> raise (Failure (exceptf n1))
      | _ :: t -> helper t
      | [] -> ()
    in helper (List.sort compare list)
  in

  (* Raise an exception if a given binding is to a void type *)
  let check_not_void exceptf = function
      (Void, n) -> raise (Failure (exceptf n))
    | _ -> ()
  in
  
  (* Raise an exception of the given rvalue type cannot be assigned to
     the given lvalue type *)
  let check_assign lvaluet rvaluet err =
     if lvaluet == rvaluet then lvaluet else raise err
  in
   
  (**** Checking Global Variables ****)

  List.iter (check_not_void (fun n -> "illegal void global " ^ n)) globals;
   
  report_duplicate (fun n -> "duplicate global " ^ n) (List.map snd globals);

  (**** Checking Functions ****)

  if List.mem "print" (List.map (fun fd -> fd.fname) functions)
  then raise (Failure ("function print may not be defined")) else ();

  report_duplicate (fun n -> "duplicate function " ^ n)
    (List.map (fun fd -> fd.fname) functions);

  (* Function declaration for a named function *)
  let built_in_decls = StringMap.add "load" 
      { typ = Pic; fname = "load"; formals = [(Void, "x")];
        body = [] } (StringMap.add "printb" 
      { typ = Void; fname = "printb"; formals = [(Bool, "x")];
        body = [] } (StringMap.add "print"
      { typ = Void; fname = "print"; formals = [(Int, "x")];
        body = [] } (StringMap.singleton "prints"
      { typ = Void; fname = "prints"; formals = [(Void, "x")];
        body = [] })))
  in
     
  let function_decls = List.fold_left (fun m fd -> StringMap.add fd.fname fd m)
                         built_in_decls functions
  in

  let function_decl s = try StringMap.find s function_decls
       with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = function_decl "main" in (* Ensure "main" is defined *)

  let check_function func =

    List.iter (check_not_void (fun n -> "illegal void formal " ^ n ^
      " in " ^ func.fname)) func.formals;

    report_duplicate (fun n -> "duplicate formal " ^ n ^ " in " ^ func.fname)
      (List.map snd func.formals);

    (*     List.iter (check_not_void (fun n -> "illegal void local " ^ n ^
          " in " ^ func.fname)) func.locals;
    *)
    (*     report_duplicate (fun n -> "duplicate local " ^ n ^ " in " ^ func.fname)
          (List.map snd func.locals);
    *)
    (* Type of each variable (global, formal, or local *)
    List.fold_left (fun tbl (t, n) -> Hashtbl.add tbl n t; tbl)
    symbols (globals @ func.formals);
    
    let type_of_identifier s =
      (* try StringMap.find s symbols *)
      try Hashtbl.find symbols s 
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in
    let pic_attr_checker s = 
      try StringMap.find s pic_attrs
      with Not_found -> raise (Failure ("attributes not found in pic:" ^ s))
    in
    (* Return the type of an expression or throw an exception *)
    let rec expr = function
        Literal _ -> Int
      | BoolLit _ -> Bool
      | StringLit _ -> Void
      | Id s -> type_of_identifier s
      | Binop(e1, op, e2) as e -> let t1 = expr e1 and t2 = expr e2 in
	    (match op with
          Add | Sub | Mult | Div when t1 = Int && t2 = Int -> Int
	       | Equal | Neq when t1 = t2 -> Bool
	       | Less | Leq | Greater | Geq when t1 = Int && t2 = Int -> Bool
	       | And | Or when t1 = Bool && t2 = Bool -> Bool
         | _ -> raise (Failure ("illegal binary operator " ^
              string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
              string_of_typ t2 ^ " in " ^ string_of_expr e)))
      | Unop(op, e) as ex -> let t = expr e in
	    (match op with
	          Neg when t = Int -> Int
	         | Not when t = Bool -> Bool
           | _ -> raise (Failure ("illegal unary operator " ^ string_of_uop op ^
	  		   string_of_typ t ^ " in " ^ string_of_expr ex)))
      | Noexpr -> Void
      | Assign(var, e) as ex -> let lt = type_of_identifier var
                                and rt = expr e in
        check_assign (type_of_identifier var) (expr e)
                 (Failure ("illegal assignment " ^ string_of_typ lt ^ " = " ^
                           string_of_typ rt ^ " in " ^ string_of_expr ex))
      | Getarr(s, e) -> ignore(type_of_identifier s); expr e
      | Assignarr(s, e1, e2) -> ignore(type_of_identifier s); ignore(expr e1); expr e2 
      | Getpic(s1, s2) -> ignore(type_of_identifier s1); ignore(pic_attr_checker s2); (StringMap.find s2 pic_attrs)
      | Assignpic(s1, s2, e) -> ignore(type_of_identifier s1); ignore(pic_attr_checker s2); expr e
      | Call(fname, actuals) as call -> let fd = function_decl fname in
         if List.length actuals != List.length fd.formals then
              raise (Failure ("expecting " ^ string_of_int
              (List.length fd.formals) ^ " arguments in " ^ string_of_expr call))
         else
           List.iter2 (fun (ft, _) e -> let et = expr e in
              ignore (check_assign ft et
                (Failure ("illegal actual argument found " ^ string_of_typ et ^
                " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e))))
             fd.formals actuals;
           fd.typ
	   
    in
    let check_bool_expr e = if expr e != Bool
        then raise (Failure ("expected Boolean expression in " ^ string_of_expr e))
        else () 
    in
    (* Temporarily check for init type and always return expr first *)

    let add_var_into_symbols s t = 
      (* print_string "add_var_into_symbols\n"; *)
      Hashtbl.add symbols s t
    in
    let check_for_init e =
      match e with 
      F_init(t1, s1, e1) -> ignore(add_var_into_symbols s1 t1); expr e1
      | F_expr e1 -> expr e1
    in
    (* Verify a statement or throw an exception *)
    let rec stmt = function
      Block sl -> 
        let rec check_block = function
            [Return _ as s] -> stmt s
            | Return _ :: _ -> raise (Failure "nothing may follow a return")
            | Block sl :: ss -> check_block (sl @ ss)
            | s :: ss -> stmt s ; check_block ss
            | [] -> ()
        in check_block sl
      | Expr e -> ignore (expr e)
      | S_bind(t, s) -> ignore (add_var_into_symbols s t)
      | S_init(t, s, e) -> ignore(add_var_into_symbols s t); ignore(expr e) (* why can this work? *)
      | Return e -> let t = expr e in if t = func.typ then () else
           raise (Failure ("return gives " ^ string_of_typ t ^ " expected " ^
                           string_of_typ func.typ ^ " in " ^ string_of_expr e))       
      | If(p, b1, b2) -> check_bool_expr p; stmt b1; stmt b2
      | For(e1, e2, e3, st) -> ignore (check_for_init e1); check_bool_expr e2; ignore (expr e3); stmt st
      | While(p, s) -> check_bool_expr p; stmt s
    in
    stmt (Block func.body)
  in
  List.iter check_function functions
