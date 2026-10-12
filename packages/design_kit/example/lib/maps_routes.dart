// Generated from the stage 1 routes; polylines are data, kept on one line.
// ignore_for_file: lines_longer_than_80_chars, unnecessary_raw_strings

// Real road routes between the seed places, as OpenRouteService built them
// (docs/MAPS.md, stage 1; © openrouteservice.org by HeiGIT, map data ©
// OpenStreetMap contributors). Static data for the previews only: the app
// gets its routes from the API.

import 'package:latlong2/latlong.dart';

/// A route: distance (m) and the Google-encoded polyline (precision 5).
typedef PreviewRoute = ({int metres, String polyline});

/// Seed trip t1.
const PreviewRoute bazaarToEsentai = (
  metres: 7203,
  polyline: r'{v`gG_iutMJzCJjEFbCTbI@TLlFDjB~CUp@Ev@ElCSTCfCOpE[ZCn@E~AIz@GtAIVpI@Z@Z@^F~BFrCdIq@FxAJrCFtBHxCZbJLjD?l@TrHZfI@j@LlEFpBFApCSzDYlE[~M{@^CjEY`BMlAE|BM`CMbDUn@GdCQbBKpBOdAGvCOZ?ZBbBK^CpBSPCnAMf@EnBSp@G~C[X?LzE@LFfCJjDFfB@^xAs@|Au@jCcA~Bs@~@W`MqBr@MnImAdCWnGo@~@O`@On@]f@]v@e@XUTWtFcIHET@LHn@z@XZjA|@vC`FdAhBhEnH`FlIR^l@bAzEdI|@zAr@lA^n@Dt@b@bATZ@F@FPRf@bATl@R^HLJTjClE',
);

/// Seed trip t2.
const PreviewRoute esentaiToRepublic = (
  metres: 5211,
  polyline: r'k`xfG{aptM|AjCCH}BlDID]EQUw@aAm@o@i@u@CCSSKEg@OYAOAw@?MAkA?MCEi@AeAA{A?IAqBN_@TQhDgBRIRCPHAGD?RVd@bAL`@Vd@jAhB`@^pBhDNTJFPALENWDY@UCYOUsCaE}BcC]m@e@u@yBwDu@kAGKi@_AiFaJy@uAeFyI{@wAqC{Ey@wAuA_CkAsBoBmEC]J_@lJeNL@\APILQFW@MCYQ_@OKU?IBOHILEREZOf@Q\iA`BuGlJoAhB_G|Ie@j@w@t@k@^oBj@aE^OBcD?_JdAU?SCUQ}@yAk@aAi@}Aw@cBu@eAiAqA}BmCS]K[IYEqA?wAQc@GEOCeADw@FcEXe@BkAFeAF[AGiBG_F?cHEcB',
);

/// Seed trip t3.
const PreviewRoute republicToAirport = (
  metres: 25641,
  polyline: r'{}{fGglstMDbB?bHF~EFhBa@AqFXuAL{AJoCPeDV[L{BNO@uAHm@DaDRsBNaBJeCPcCPK?K@wDViG`@aAHoBLs@DoCPiF\kCPiCN[BgDRK@cEVg@D{AHuAJ{AHWBkCPaCNI?wAJoBLgBJaHb@uAHUBi@BaAFSBmDT}G`@qJl@UyIMyDQgFQoGMgEIsCyAJwHf@wAFeBF[@S@yBH]?cADo@@yAD}AWSEk@MkC{@yAc@iAUi@Ey@?_@Ca@ISIYSU[IQSu@E]GcAC}AGeC?YC}AcAHE@qEZeHd@U@S?mB@eIDcE@M@eAB_@@K@gADcDH_ADoGP_BFC{BGqCMmESaEQqDIwDCeBGyAQeEKgEOwDQ}DMaC?UBQgCk@YEiE[aDUsD[qCKyCBUOM]M}BIyAE]KQ{@@IcA_A}HM}A]DLbBLdAt@~FGh@GLe@T}Bd@{@HeAAu@Mo@Me@SOIo@]w@s@oBaBeB_BgB_BoAaA[YuBgBqB{Ak@]iAs@uAq@wB}@wBm@wBk@uBg@cCi@}Be@iCi@{Bg@wBa@{Be@wCq@sBk@kBImBAeBCmB?oB?kBAqACoCGkAYmAm@mBaAkJkEmB_A}HqDuJoEYMoHkD_Ac@oCuA[QcAy@wKmFuAq@aF_CiM}FaHmCaBs@eFmBkAm@o@o@qAyA{BuBm@e@wHoEaF{CqAy@_By@iAk@iFwBsEwB{@k@cA{@g@m@q@gA[i@}@kBmC{E[u@[s@gDoHgGwMK[G[GiA@e@PcCt@{Ej@mDLu@DYp@yED[Ak@e@iEM{AMkA_@wDo@uEOy@oAoEaAkEMm@[qAw@yCUeAmCmLo@uC_@gB_@PoBx@uGjCyCfAa@Ng@Tk@XeGrBe@JsAPcA?{@SoBk@]KsBo@eAa@QIi@Qa@QkBi@kAWWEy@Ey@?kBHC?w@B{@CUFCKGOo@uASo@iAwHgBaMm@qEgAyHaAsGQgAc@sCkAmH_B{JCO|BaAtCeAzDyAH?FDFTl@OVDFBJRtC|P?Xa@fAMLZtBdCZ`[qKdAOlA@?tA?LDHpCNLiJzDL?M|B?j@BMpFMnJGtD?T@HDBxAFpCn@n@]VHNb@FDtAh@NBHAjDkBDT@Z~@lE`@rBNn@|Ay@AJ\zAXpAvFuCVlA`DiB\KJFHHb@lAx@tCP`@j@h@dDdB|G~DdC|Af@Tn@L\@`@KfAi@r@UXWRYH[Fa@?g@E_@yCoHcM}[Mg@g@gEnAgADa@q@}C]M_@L]GSOaAgGM_@aAoBsD}GUOO?sBVKEQSgQwc@iIkSiMa\}E}LsAoDc@kA',
);

/// Seed trip t4.
const PreviewRoute megaToBazaar = (
  metres: 12356,
  polyline: r'e~tfGmkitMZ?^Op@EFA\GcDGW?Q?Y?Q?uC@[F@o@?a@B{J?EIcJA}ABs@iCJyCNI@i@BeDTQ@WByAJeDRyBN_AFcAHcCNS@aAH_CNg@DuBLwAJoEZwE\iEZy@FsAJi@DaBJyDXM@qBNK@{BNkBLiBJgBLO@}AHc@ByCROgFAWA_@M}DGmBIaC?IOeFsCRyDXs@DoDV_@Di@Bi@Dq@DcCNs@DuAHiAHS@gCPsCRyAJgBLo@DWBi@D_AFg@DQ@eDTsCPeDTg@DkAHoDTgAHoCRoAJsAHsEZk@DO@sBNcAFsCPY@eETqE\wCTkIh@C_ACkAIyBMkEM{EEeAA_@G}BKqDSyGIqCM}DG_CIwBEaBAUCaAKcDKsDC_@CiAIaCCc@EaBKiDC_AA]EqAGkBGsByIj@qIr@yFZqAHcBJmF\O@_EZkCLI{DIeCCqBEmAOuFKiDEoAE_BE{ASgGqDXeDTSBs@BuBLqCNKoEGaCK{DKaDY}HUeHE{AKqEGcDGoBOoFKiDCk@KkCYqIQoGEgBAGSwHEsAOeGKkDMmDMsDEy@GgBW_JWqIAWWoIIcDOcFA_@SiGKiDIcDUwIMoEEyB{AJyBNY@gDTBjAPdGLpD??',
);

/// Seed trip u2-t2.
const PreviewRoute megaToEsentai = (
  metres: 5525,
  polyline: r'e~tfGmkitMZ?^Op@EFA\GcDGW?Q?Y?Q?uC@[F@o@?a@B{J?EIcJA}ABs@D_@?qAH]?oACcBCg@Eo@E_JGsE~BQhASh@QhA]dAi@fBkAtAcAx@o@bCeBd@QRAJFFHDV?HCLKNaBlA]TYFYESUU]Sq@Y_BK}AOsGG}BEq@MmAOq@WcAi@wAc@{@_CyDsCiEqA_Bm@k@WQsBm@qAKkIIcBS]I]OWU_BkBsEeHWa@kAgBe@u@cF_IkDmFoE}GiMkRw@sA}@iB}@gBCc@i@mB_@aAo@qAUs@[y@OQMGS?IB]^{@jAeBpCGFK@IAYQQUw@aAm@o@i@u@CCSSKEg@OYAOAw@?MAkA?MCEi@AeAA{A?IAqBN_@TQhDgBRIRCPHPRf@bATl@R^HLJTjClE',
);

/// Decodes a Google-encoded polyline (precision 5). A copy for the previews;
/// the app has its own, tested decoder in its domain layer.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  int next() {
    var shift = 0;
    var result = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return result.isOdd ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
