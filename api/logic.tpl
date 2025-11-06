// Code scaffolded by goctl. Safe to edit.
// goctl {{.version}}

package {{.pkgName}}

import (
	{{- if contains .logic "GameInfoGet" }}
		"context"
    	"encoding/json"
    	"qstar-server/internal/generic/errors"
	    "qstar-server/internal/generic/key"
    	"qstar-server/internal/module/player"
    	"qstar-server/service/action/internal/logic/basefunc/basepg"
    	"qstar-server/service/action/internal/logic/pocketgames/pgpkg"
    	"qstar-server/service/action/internal/svc"
    	"qstar-server/service/action/internal/types"
    	"qstar-server/service/slots/types/cli"
    	"qstar-server/service/thirdfunc/base"

    	"github.com/acoderup/boost/mathx"
    	"github.com/zeromicro/go-zero/core/logx"
	{{- else }}
        "context"
    	"encoding/json"
    	"fmt"
    	"qstar-server/internal/generic/errors"
    	"qstar-server/internal/generic/key"
    	"qstar-server/service/action/internal/logic/basefunc/basepg"
    	"qstar-server/service/action/internal/svc"
    	"qstar-server/service/action/internal/types"
    	"qstar-server/service/slots/types/cli"
    	"qstar-server/service/thirdfunc/base"

    	"github.com/acoderup/boost/mathx"
    	"github.com/zeromicro/go-zero/core/logx"
	{{- end }}
)
{{- if contains .logic "GameInfoGet" }}
const Theme = key.{{extractGameName .logic}}
{{- else }}
type CustomEg struct {
	VectorEg  string
	VectorId  int64
	VectorIdx int
	DfMul     float64
}
{{- end }}
type {{.logic}} struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
	{{- if contains .logic "GameInfoGet" }}
	basepg.PGEnterCaller
	{{- else }}
	basepg.PGSpinCaller
	{{- end }}
}

{{- if contains .logic "GameInfoGet" }}
func (l *{{.logic}}) HandleDt(Response *cli.SlotsEnterResponse, bpg *basepg.BasePG) any {
    p := player.Get(bpg.GetSession())
    var gameinfo GameInfo
    err := json.Unmarshal([]byte(GameInfoDtStr), &gameinfo)
    if err != nil {
    	panic(err)
    }
    gameinfo.Dt.Cs = nil
    for _, v := range Response.BetSizes {
    	gameinfo.Dt.Cs = append(gameinfo.Dt.Cs, pgpkg.ItoF(v))
    }
    gameinfo.Dt.Ml = Response.BetLevels
    firstBet := Response.FirstBet
    gameinfo.Dt.Ls.Si.Cs = gameinfo.Dt.Cs[firstBet[0]]
    gameinfo.Dt.Ls.Si.Ml = gameinfo.Dt.Ml[firstBet[1]]

    gameinfo.Dt.Bl = mathx.CoinToFloat(p.Coin())
    gameinfo.Dt.Ls.Si.Bl = mathx.CoinToFloat(p.Coin())

    //cc
	gameinfo.Dt.Cc = bpg.GetCc()
	//wt
	gameinfo.Dt.Wt.Mw = 5
	gameinfo.Dt.Wt.Bw = 20
	gameinfo.Dt.Wt.Mgw = 35
	gameinfo.Dt.Wt.Smgw = 50

	return gameinfo.Dt
}
{{- else }}
func (l *{{.logic}})HandSi(req *types.SpinRequest, Response *cli.SlotsPlayResponse, bpg *basepg.BasePG) any {
	customEg := basepg.GetFeatureData[CustomEg](bpg)
	var spin SpinDt
	err := json.Unmarshal([]byte(customEg.VectorEg), &spin)
	if err != nil {
		panic(err)
	}
	baseNode := Response.GetBaseNode()
	cursor := Response.GetCursorNode()
	si := spin.Dt.Si
	if cursor.Type == key.BaseSpin {
		si.Psid = fmt.Sprint(cursor.Sid)
		si.Sid = fmt.Sprint(cursor.Sid)
	} else {
		si.Psid = fmt.Sprint(baseNode.Sid)
		si.Sid = fmt.Sprint(cursor.Sid)
	}

	//aw
	si.Aw = mathx.RoundFloat(si.Aw * customEg.DfMul)
	aw := mathx.FloatToCoin(si.Aw)

	//tw
	si.Tw = mathx.RoundFloat(si.Tw * customEg.DfMul)
	tw := mathx.FloatToCoin(si.Tw)

	si.Ctw = mathx.RoundFloat(si.Ctw * customEg.DfMul)

	si.Hashr = ""

	var blb, bl, blab int64
	if !Response.IsEnd {
		blb = Response.Coin + aw + Response.ActualBet - tw //下注前
		blab = Response.Coin + aw - tw                     //下注后
		bl = Response.Coin + aw                            //当前金额
	} else {
		blb = Response.Coin + Response.ActualBet - tw //下注前
		blab = Response.Coin - tw                     //下注后
		bl = Response.Coin                            //当前金额
	}
	si.Blb = mathx.CoinToFloat(blb)
	si.Blab = mathx.CoinToFloat(blab)
	si.Bl = mathx.CoinToFloat(bl)

	si.Cs = req.Cs
	si.Ml = req.Ml
	//lw
	if si.Lw != nil {
		lwMap := si.Lw.(map[string]interface{})
		for k, v := range lwMap {
			val, _ := v.(float64)
			lwMap[k] = mathx.RoundFloat(val * customEg.DfMul)
		}
		si.Lw = lwMap
	}
	si.Np = mathx.RoundFloat(si.Np * customEg.DfMul)

	si.Tb = mathx.RoundFloat(si.Tb * customEg.DfMul)
	si.Tbb = mathx.RoundFloat(si.Tbb * customEg.DfMul)
	si.Ssaw = mathx.RoundFloat(si.Ssaw * customEg.DfMul)

	return si
}
{{- end }}
{{if .hasDoc}}{{.doc}}{{end}}
func New{{.logic}}(ctx context.Context, svcCtx *svc.ServiceContext) *{{.logic}} {
	return &{{.logic}}{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *{{.logic}}) {{.function}}({{.request}}) {{.responseType}} {
	{{- if contains .logic "GameInfoGet" }}
	resp = new(types.PGRespose)
    	bpg := basepg.NewBasePG(Theme, req.Ip, l.ctx, l.svcCtx)
    	dtInf, err := bpg.PGEnter(req.Atk, l)
    	if err != nil {
    		resp.Err = base.SetErr(errors.EnterErr, err.Error(), "enter", req.Ip)
    		return
    	}
    	resp.Dt = dtInf
	{{- else }}
	resp = new(types.PGRespose)
    	bpg := basepg.NewBasePG(Theme, req.Ip, l.ctx, l.svcCtx)
    	si, err := bpg.PGSpin(req, l)
    	if err != nil {
    		base.SetErr(errors.SpinErr, err.Error(), "play", req.Ip)
    		resp.Err = bpg.ThirdError(err)
    		return
    	}
    	resp.Dt = Dt{Si: si.(*Si)}
	{{- end }}
	{{.returnString}}
}
