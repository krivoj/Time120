unit pashelp;

interface
const HELP_ClientLoadFormation = 1;
// Carica ad esempio il file in dirSaves f131.120 ch è il file che contiene SOLO i player.

const HELP_MyTeam22 = 2;
// uso un array di 22 elementi fissi ma solo all'inizio. per il resto del gioco uso lstplayerDB

const HELP_STARTSIMULATION = 3;
{ Riempe i brain passando da createformation, applica a pioggia cartellini, injured, xp , stamina. risultato calcolato con resultpreset e
usa i file di byte da cui eliminare a coppie 2 byte. Sono sempre pari quindi. Poi passa dal finalizebrain.
}
implementation

end.
