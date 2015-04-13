killua.op_names = {
	[0]="ISLT","ISGE","ISLE","ISGT",															--DONE
	"ISEQV","ISNEV","ISEQS","ISNES","ISEQN","ISNEN","ISEQP","ISNEP",							--DONE
	"ISTC","ISFC","IST","ISF",																	--DONE
	"MOV","NOT","UNM","LEN",																	--DONE
	"ADDVN","SUBVN","MULVN","DIVVN","MODVN",													--DONE
	"ADDNV","SUBNV","MULNV","DIVNV","MODNV",													--DONE
	"ADDVV","SUBVV","MULVV","DIVVV","MODVV",													--DONE
	"POW","CAT",																				--DONE
	"KSTR","KCDATA","KSHORT","KNUM","KPRI","KNIL",												--DONE
	"UGET","USETV","USETS","USETN","USETP","UCLO","FNEW",										--DONE
	"TNEW","TDUP","GGET","GSET","TGETV","TGETS","TGETB","TSETV","TSETS","TSETB","TSETM",		--DONE
	"CALLM","CALL","CALLMT","CALLT","ITERC","ITERN","VARG","ISNEXT",												--TODO 2 -- fukn tailcalls
	"RETM","RET","RET0","RET1",																	--DONE
	"FORI","JFORI",																				--DONE
	"FORL","IFORL","JFORL",																		--DONE
	"ITERL","IITERL","JITERL",																	--DONE
	"LOOP","ILOOP","JLOOP",																		--DONE
	"JMP",																						--DONE
	"FUNCF","IFUNCF","JFUNCF","FUNCV","IFUNCV","JFUNCV","FUNCC","FUNCCW"						--NOT IN DUMP
}

local ops = {}

--Comparison
ops[0] = {"ld a var","ld d var","cmp lt"}
ops[1] = {"ld a var","ld d var","cmp ge"}
ops[2] = {"ld a var","ld d var","cmp le"}
ops[3] = {"ld a var","ld d var","cmp gt"}

--Equality
ops[4] = {"ld a var","ld d var","cmp eq"}
ops[5] = {"ld a var","ld d var","cmp neq"}
ops[6] = {"ld a var","ld d str","cmp eq"}
ops[7] = {"ld a var","ld d str","cmp neq"}
ops[8] = {"ld a var","ld d num","cmp eq"}
ops[9] = {"ld a var","ld d num","cmp neq"}
ops[10] = {"ld a var","ld d pri","cmp eq"}
ops[11] = {"ld a var","ld d pri","cmp neq"}

--Unary Test/Copy
ops[12] = {"ld a lit","ld d var","is t c"}
ops[13] = {"ld a lit","ld d var","is f c"}
ops[14] = {"ld d var","is t"}
ops[15] = {"ld d var","is f"}

--Unary
ops[16] = {"ld a lit","ld d var","sv d"}
ops[17] = {"ld a lit","ld d var","un not","sv d"}
ops[18] = {"ld a lit","ld d var","un minus","sv d"}
ops[19] = {"ld a lit","ld d var","un len","sv d"}

--Maths
ops[20] = {"ld a lit","ld b var","ld c num","math add b c","sv b"}
ops[21] = {"ld a lit","ld b var","ld c num","math sub b c","sv b"}
ops[22] = {"ld a lit","ld b var","ld c num","math mul b c","sv b"}
ops[23] = {"ld a lit","ld b var","ld c num","math div b c","sv b"}
ops[24] = {"ld a lit","ld b var","ld c num","math mod b c","sv b"}

ops[25] = {"ld a lit","ld b var","ld c num","math add c b","sv b"}
ops[26] = {"ld a lit","ld b var","ld c num","math sub c b","sv b"}
ops[27] = {"ld a lit","ld b var","ld c num","math mul c b","sv b"}
ops[28] = {"ld a lit","ld b var","ld c num","math div c b","sv b"}
ops[29] = {"ld a lit","ld b var","ld c num","math mod c b","sv b"}

ops[30] = {"ld a lit","ld b var","ld c var","math add b c","sv b"}
ops[31] = {"ld a lit","ld b var","ld c var","math sub b c","sv b"}
ops[32] = {"ld a lit","ld b var","ld c var","math mul b c","sv b"}
ops[33] = {"ld a lit","ld b var","ld c var","math div b c","sv b"}
ops[34] = {"ld a lit","ld b var","ld c var","math mod b c","sv b"}

--Misc Maths
ops[35] = {"ld a lit","ld b var","ld c var","math pow b c","sv b"}
ops[36] = {"ld a lit","ld b lit","ld c lit","cat","sv b"}

--Konstants
ops[37] = {"ld a lit","ld d str","sv d"}
//KCDATA not implemented.
ops[39] = {"ld a lit","ld d lits","sv d"}
ops[40] = {"ld a lit","ld d num","sv d"}
ops[41] = {"ld a lit","ld d pri","sv d"}
ops[42] = {"ld a lit","ld d lit","sv nils"}

--Upvalues, Closures
ops[43] = {"ld a lit","ld d lit","uv get","sv d"}
ops[44] = {"ld a lit","ld d var","uv set"}
ops[45] = {"ld a lit","ld d str","uv set"}
ops[46] = {"ld a lit","ld d num","uv set"}
ops[47] = {"ld a lit","ld d pri","uv set"}
ops[48] = {"ld a lit","ld d lit","uv close","jmp"}
ops[49] = {"ld a lit","ld d func","sv d"}

--Table
ops[50] = {"ld a lit","sv t"}
ops[51] = {"ld a lit","ld d tbl","sv d"}
ops[52] = {"ld a lit","ld d str","tget g d","sv d"}
ops[53] = {"ld a var","ld d str","tset g d a"}
ops[54] = {"ld a lit","ld b var","ld c var","tget b c","sv c"}
ops[55] = {"ld a lit","ld b var","ld c str","tget b c","sv c"}
ops[56] = {"ld a lit","ld b var","ld c lit","tget b c","sv c"}
ops[57] = {"ld a var","ld b var","ld c var","tset b c a"}
ops[58] = {"ld a var","ld b var","ld c str","tset b c a"}
ops[59] = {"ld a var","ld b var","ld c lit","tset b c a"}
ops[60] = {"ld a lit","ld d wtf","tset multi"}

--Calls
ops[61] = {"ld a lit","ld b lit","ld c lit","call multi"}
ops[62] = {"ld a lit","ld b lit","ld c lit","call"}

ops[63] = {"ld a lit","ld b lit","ld c lit","call multi tail"}
ops[64] = {"ld a lit","ld b lit","ld c lit","call tail"}
ops[65] = {"ld a lit","ld b lit","call iter"}
ops[66] = {"ld a lit","ld b lit","call next"}
ops[67] = {"ld a lit","ld b lit","sv vargs"}
ops[68] = {"ld a lit","ld d lit","is next","jmp"}

--Returns
ops[69] = {"ld a lit","ld d lit","ret multi"}
ops[70] = {"ld a lit","ld d lit","ret"}
ops[71] = {"ret zero"}
ops[72] = {"ld a var","ret one"}

--Loops/Jumps
ops[73] = {"ld a lit","ld d lit","for init","jmp"}
//JIT VERSION^
ops[75] = {"ld a lit","ld d lit","for loop","jmp"}
//NO-JIT VERSION^
//JIT VERSION^
ops[78] = {"ld a lit","ld d lit","for iter","jmp"}
//NO-JIT VERSION^
//JIT VERSION^
ops[81] = {} //"actually no-ops"
//NO-JIT VERSION^
//JIT VERSION^
ops[84] = {"ld d lit","jmp"}

killua.ops = ops