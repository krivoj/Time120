Install Overbyte Packages.
http://www.overbyte.eu/frame_index.html


Changes unit OverbyteIcsWSocketS.pas: 

    TWSocketClient = class(TWSocket)
    protected
        FBanner            : String;
        FServer            : TCustomWSocketServer;
        FPeerAddr          : String;
        FPeerPort          : String;
        FSessionClosedFlag : Boolean;
        FCliId             : LongInt;          { angus V7.00 }
    public
        LastTickCount : Integer;
        GmLevel: Integer;

        idxDeckAndClass: array [0..1] of Byte;
        SelectedDeck: array [0..1] of string;

        GameType: string[2];
        GuidTeam: Integer;
        WorldTeam: Integer;
        teamName: string;
        UserName: string;
        info: string;
        MarketValueTeam: Integer;
        Marked: boolean;
        nextHA: integer;
        Rank: integer;
        mi: Integer;
        sreason: string;
        Processing: Boolean;
        PwdTicket : string;
        sPassword : string;
        Flags: Integer;
        TimeStartQueue: Integer;
        Brain : TObject;
        Account : Integer;
        procedure   StartConnection; virtual;

		
		Done!