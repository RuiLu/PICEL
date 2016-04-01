(* Abstract Syntax Tree and functions for printing it *)

type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq | And | Or | Dadd | Dsub | Dmul | Conv

type uop = Neg | Not

type single_typ = Int | Bool | Char

type typ = Int | Bool | Char | Array of single_typ | Pic | Void

type bind = typ * string

type expr = 
  Literal of int
  | Id of string
  | StringLit of string
  | CharLit of char
  | BoolLit of bool
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Call of string * expr list
  | Noexpr

type initialization = typ * string * expr

type vdecl =  Bind of bind

type for_init = 
  Init of initialization
  | Expr of expr

type stmt = 
  Block of stmt list
  | Expr of expr
  | If of expr * stmt * stmt
  | For of for_init * expr * expr * stmt
  | While of expr * stmt
  | Return of expr
  | S_bind of bind
  | S_init of initialization
  | Vdecl of vdecl
  | Delete of string

type func_decl = {
  typ: typ;
  fname: string;
  formals: bind list;
  body: stmt list;
}

type decl = Vdecl of vdecl
  | Fdecl of func_decl

type  program = decl list


(* test print *)
(*let string_of_typ = function
    Int -> "int"
  | Bool -> "bool"
  | Void -> "void"

let rec string_of_expr = function
    StringLit(s) -> s
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_program (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs)
*)

(* Pretty-printing functions *)

 let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"

let string_of_uop = function
    Neg -> "-"
  | Not -> "!"

let rec string_of_expr = function
    Literal(l) -> string_of_int l
  | StringLit(s) -> "\"" ^ s ^ "\""
  | BoolLit(true) -> "true"
  | BoolLit(false) -> "false"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  (*| For(e1, e2, e3, s) ->
      "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
      string_of_expr e3  ^ ") " ^ string_of_stmt s
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s*)

let string_of_typ = function
    Int -> "int"
  | Bool -> "bool"
  | Void -> "void"


let string_of_bind (t, id) =
  string_of_typ t ^ " " ^ id ^ ";\n"

let string_of_vdecl = function
  Bind(bind) -> string_of_bind bind

let string_of_fdecl fdecl =
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  (*String.concat "" (List.map string_of_vdecl fdecl.locals) ^*)
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_decl = function
  Vdecl(vdecl) -> string_of_vdecl vdecl  ^ "\n" 
  |Fdecl(func_decl) -> " " ^ string_of_fdecl func_decl ^ "\n"

(*let string_of_decl (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs)*)

let string_of_program (decls) =
  String.concat "" (List.map string_of_decl decls)

