// Trips with places and real routes (the ORS routes of the seed trips,
// docs/MAPS.md stage 1), for the map tests and screenshots.
// ignore_for_file: lines_longer_than_80_chars, unnecessary_raw_strings

import 'package:driver_diary/features/trips/domain/entities/place.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_route.dart';

import 'fixtures.dart';

/// The fake accounts' ids (fakes.dart).
const driver1Id = 'u1';
const driver2Id = 'u2';

const bazaar = Place(
  point: GeoPoint(43.26275, 76.95519),
  label: 'Зелёный базар',
);
const esentai = Place(
  point: GeoPoint(43.2189, 76.9279),
  label: 'ТРЦ Есентай Молл',
);
const republic = Place(
  point: GeoPoint(43.238, 76.9455),
  label: 'Площадь Республики',
);
const airport = Place(
  point: GeoPoint(43.3521, 77.0405),
  label: 'Аэропорт Алматы',
);
const mega = Place(
  point: GeoPoint(43.2026, 76.8946),
  label: 'ТРЦ MEGA Alma-Ata',
);

const TripRoute bazaarToEsentai = TripRoute(
  status: RouteStatus.ready,
  distanceMetres: 7496,
  polyline: r'{v`gG_iutMJzCJjEFbCTbI@TLlFDjB~CUp@Ev@ElCSTCfCOpE[ZCn@E~AIz@GtAIVpI@Z@Z@^F~BFrCdIq@FxAJrCFtBHxCZbJLjD?l@TrHZfI@j@LlEFpBFApCSzDYlE[~M{@^CjEY`BMlAE|BM`CMbDUn@GdCQbBKpBOdAGvCOZ?ZBbBK^CpBSPCnAMf@EnBSp@G~C[X?LzE@LFfCJjDFfB@^xAs@|Au@jCcA~Bs@~@W`MqBr@MnImAdCWnGo@~@O`@On@]f@]v@e@XUTWtFcIHET@LHn@z@XZjA|@vC`FdAhBhEnH`FlIR^l@bAzEdI|@zAr@lA^n@Dt@b@bATZ@F@FPRf@bATl@R^HLJThFxICH}BlDID]EQUw@aAm@o@CC',
);

const TripRoute esentaiToRepublic = TripRoute(
  status: RouteStatus.ready,
  distanceMetres: 4918,
  polyline: r'sfxfGc|otMe@q@CCSSKEg@OYAOAw@?MAkA?MCEi@AeAA{A?IAqBN_@TQhDgBRIRCPHAGD?RVd@bAL`@Vd@jAhB`@^pBhDNTJFPALENWDY@UCYOUsCaE}BcC]m@e@u@yBwDu@kAGKi@_AiFaJy@uAeFyI{@wAqC{Ey@wAuA_CkAsBoBmEC]J_@lJeNL@\APILQFW@MCYQ_@OKU?IBOHILEREZOf@Q\iA`BuGlJoAhB_G|Ie@j@w@t@k@^oBj@aE^OBcD?_JdAU?SCUQ}@yAk@aAi@}Aw@cBu@eAiAqA}BmCS]K[IYEqA?wAQc@GEOCeADw@FcEXe@BkAFeAF[AGiBG_F?cHEcB',
);

const TripRoute republicToAirport = TripRoute(
  status: RouteStatus.ready,
  distanceMetres: 25641,
  polyline: r'{}{fGglstMDbB?bHF~EFhBa@AqFXuAL{AJoCPeDV[L{BNO@uAHm@DaDRsBNaBJeCPcCPK?K@wDViG`@aAHoBLs@DoCPiF\kCPiCN[BgDRK@cEVg@D{AHuAJ{AHWBkCPaCNI?wAJoBLgBJaHb@uAHUBi@BaAFSBmDT}G`@qJl@UyIMyDQgFQoGMgEIsCyAJwHf@wAFeBF[@S@yBH]?cADo@@yAD}AWSEk@MkC{@yAc@iAUi@Ey@?_@Ca@ISIYSU[IQSu@E]GcAC}AGeC?YC}AcAHE@qEZeHd@U@S?mB@eIDcE@M@eAB_@@K@gADcDH_ADoGP_BFC{BGqCMmESaEQqDIwDCeBGyAQeEKgEOwDQ}DMaC?UBQgCk@YEiE[aDUsD[qCKyCBUOM]M}BIyAE]KQ{@@IcA_A}HM}A]DLbBLdAt@~FGh@GLe@T}Bd@{@HeAAu@Mo@Me@SOIo@]w@s@oBaBeB_BgB_BoAaA[YuBgBqB{Ak@]iAs@uAq@wB}@wBm@wBk@uBg@cCi@}Be@iCi@{Bg@wBa@{Be@wCq@sBk@kBImBAeBCmB?oB?kBAqACoCGkAYmAm@mBaAkJkEmB_A}HqDuJoEYMoHkD_Ac@oCuA[QcAy@wKmFuAq@aF_CiM}FaHmCaBs@eFmBkAm@o@o@qAyA{BuBm@e@wHoEaF{CqAy@_By@iAk@iFwBsEwB{@k@cA{@g@m@q@gA[i@}@kBmC{E[u@[s@gDoHgGwMK[G[GiA@e@PcCt@{Ej@mDLu@DYp@yED[Ak@e@iEM{AMkA_@wDo@uEOy@oAoEaAkEMm@[qAw@yCUeAmCmLo@uC_@gB_@PoBx@uGjCyCfAa@Ng@Tk@XeGrBe@JsAPcA?{@SoBk@]KsBo@eAa@QIi@Qa@QkBi@kAWWEy@Ey@?kBHC?w@B{@CUFCKGOo@uASo@iAwHgBaMm@qEgAyHaAsGQgAc@sCkAmH_B{JCO|BaAtCeAzDyAH?FDFTl@OVDFBJRtC|P?Xa@fAMLZtBdCZ`[qKdAOlA@?tA?LDHpCNLiJzDL?M|B?j@BMpFMnJGtD?T@HDBxAFpCn@n@]VHNb@FDtAh@NBHAjDkBDT@Z~@lE`@rBNn@|Ay@AJ\zAXpAvFuCVlA`DiB\KJFHHb@lAx@tCP`@j@h@dDdB|G~DdC|Af@Tn@L\@`@KfAi@r@UXWRYH[Fa@?g@E_@yCoHcM}[Mg@g@gEnAgADa@q@}C]M_@L]GSOaAgGM_@aAoBsD}GUOO?sBVKEQSgQwc@iIkSiMa\}E}LsAoDc@kA',
);

const TripRoute megaToEsentai = TripRoute(
  status: RouteStatus.ready,
  distanceMetres: 4660,
  polyline: r'w~tfGgnitM@p@W?Q?Y?Q?uC@[F@o@?a@B{J?EIcJA}ABs@D_@?qAH]?oACcBCg@Eo@E_JGsE~BQhASh@QhA]dAi@fBkAtAcAx@o@bCeBd@QRAJFFHDV?HCLKNaBlA]TYFYESUU]Sq@Y_BK}AOsGG}BEq@MmAOq@WcAi@wAc@{@_CyDsCiEqA_Bm@k@WQsBm@qAKkIIcBS]I]OWU_BkBsEeHWa@kAgBe@u@cF_IkDmFoE}GiMkRw@sA}@iB}@gBCc@i@mB_@aAo@qAUs@[y@OQMGS?IB]^{@jAeBpCGFK@IAYQQUw@aAm@o@CC',
);

/// t1 with its places and road route (08:10–08:32, 2 400 ₸, card).
final mapT1 = Trip(
  id: 't1',
  start: t1.start,
  end: t1.end,
  amount: t1.amount,
  payment: t1.payment,
  commission: t1.commission,
  driverId: driver1Id,
  pickup: bazaar,
  dropoff: esentai,
  route: bazaarToEsentai,
);

/// t2 with its places and road route (09:05–09:20, 1 500 ₸, cash).
final mapT2 = Trip(
  id: 't2',
  start: t2.start,
  end: t2.end,
  amount: t2.amount,
  payment: t2.payment,
  commission: t2.commission,
  driverId: driver1Id,
  pickup: esentai,
  dropoff: republic,
  route: esentaiToRepublic,
);

/// u2-t1 / u2-t2 (user_2) with places and routes.
final mapU2t1 = Trip(
  id: u2t1.id,
  start: u2t1.start,
  end: u2t1.end,
  amount: u2t1.amount,
  payment: u2t1.payment,
  commission: u2t1.commission,
  driverId: driver2Id,
  pickup: republic,
  dropoff: airport,
  route: republicToAirport,
);
final mapU2t2 = Trip(
  id: u2t2.id,
  start: u2t2.start,
  end: u2t2.end,
  amount: u2t2.amount,
  payment: u2t2.payment,
  commission: u2t2.commission,
  driverId: driver2Id,
  pickup: mega,
  dropoff: esentai,
  route: megaToEsentai,
);

/// t1 when the map service was down: a straight line, no duration.
final Trip mapT1Straight = mapT1.withRoute(
  const TripRoute(
    status: RouteStatus.straight,
    distanceMetres: 5354,
    polyline: r'ew`gG}hutM`qGpiD',
  ),
);

/// t2 whose route is not built yet.
final Trip mapT2Pending = mapT2.withRoute(
  const TripRoute(status: RouteStatus.pending),
);
