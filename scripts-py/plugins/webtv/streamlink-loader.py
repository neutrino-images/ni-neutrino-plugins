# 23/11/2026
# Version 0.1.0
#
# WebTV-Livestream-Script fuer Neutrino (benoetigt Neutrino mit Python-
# Unterstuetzung, --enable-python).
#
# Neutrino uebergibt die Kanal-URL als sys.argv[1] und erwartet in der
# globalen Variable 'result' das Ergebnis, z.B. {"url": "..."}.
# Bleibt 'result' leer, gilt der Aufruf als fehlgeschlagen.
#
# Streamlink wird direkt als Python-Modul benutzt. Ist das Modul nicht
# importierbar, wird wie bisher das streamlink-Kommando aufgerufen.

import ssl
import subprocess
import sys
import urllib.request

# Reihenfolge der gewuenschten Qualitaeten, die erste vorhandene gewinnt
QUALITIES = ["1080p", "720p", "3300k", "2300k", "2100k", "best"]
TIMEOUT = 30

result = None


def log(msg):
	# Die Konsole der Box ist nicht unbedingt UTF-8: nie an einem Umlaut scheitern
	line = ("[streamlink-loader.py] %s\n" % msg).encode("utf-8", "replace")
	try:
		sys.stderr.buffer.write(line)
		sys.stderr.flush()
	except Exception:
		pass


def resolve_redirect(url):
	"""stvp-Links auf die eigentliche URL aufloesen (wie curl -kLs -w %{url_effective})."""
	ctx = ssl.create_default_context()
	ctx.check_hostname = False
	ctx.verify_mode = ssl.CERT_NONE
	req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
	with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as resp:
		return resp.geturl().strip()


def stream_url_module(url):
	"""Beste Stream-URL ueber die Streamlink-Python-API."""
	from streamlink import Streamlink

	session = Streamlink()
	streams = session.streams(url)
	for quality in QUALITIES:
		stream = streams.get(quality)
		if stream is None:
			continue
		try:
			return stream.to_url()
		except TypeError:
			# Stream-Typ ohne direkte URL, naechste Qualitaet probieren
			continue
	return ""


def stream_url_cli(url):
	"""Fallback: streamlink-Kommando wie im alten Lua-Script."""
	out = subprocess.run(
		["streamlink", url, ",".join(QUALITIES), "--stream-url"],
		stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
		timeout=TIMEOUT, check=False
	)
	return out.stdout.decode("utf-8", "replace").strip()


def main():
	if len(sys.argv) < 2 or not sys.argv[1]:
		log("Keine URL übergeben")
		return None

	url = sys.argv[1]
	final_url = url

	# stvp-Links aufloesen
	if "stvp" in url:
		try:
			final_url = resolve_redirect(url)
		except Exception as e:
			log("Weiterleitung fehlgeschlagen: %s" % e)
			return None

	if not final_url:
		return None

	try:
		try:
			stream_url = stream_url_module(final_url)
		except ImportError:
			stream_url = stream_url_cli(final_url)
	except Exception as e:
		log("Streamlink-Fehler: %s" % e)
		return None

	if not stream_url:
		return None

	return {"url": stream_url}


result = main()
