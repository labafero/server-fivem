// Faixas autorais da intro. Os arquivos ficam em public/audio/ (copiados pelo
// Vite pro dist/audio/ sem hash, ver vite.config.js) e são sincronizados pro
// resource via labafero.json (rota "qb-loading", target.dirs["assets/labafero-audio"]).
// Pra adicionar/remover uma faixa: solte o arquivo em public/audio/ e liste o
// nome aqui.
const AUDIO_BASE_PATH = "/assets/labafero-audio/";
const TRACK_FILES = ["sentindo-nada.mp3", "sky.mp3"];

export const TRACKS = TRACK_FILES.map((file) => AUDIO_BASE_PATH + file);
