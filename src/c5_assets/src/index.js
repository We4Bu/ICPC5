import { c5 } from "../../declarations/c5";
import { Principal } from "@dfinity/principal";
import { AuthClient } from "@dfinity/auth-client";
import { sha256 } from "js-sha256";

let myId;

async function getPrincipal() {
  const auth = await AuthClient.create();
  myId = String(auth.getIdentity().getPrincipal());
  document.getElementById("principal").innerHTML = myId;
  console.log(myId);
}

async function getMember() {
  let section = document.getElementById("member");
  section.replaceChildren([]);
  const content = await c5.getMember();
  console.log(content);
  let len = content.length;
  for (var i = 0; i < len; ++i) {
    let p = document.createElement("p");
    p.innerText = String(content[i]);
    section.appendChild(p);
  }
}

async function getCanister() {
  let section = document.getElementById("canister");
  section.replaceChildren([]);
  const content = await c5.getCanister();
  console.log(content);
  let len = content.length;
  for (var i = 0; i < len; ++i) {
    let p = document.createElement("p");
    p.innerText = String(content[i][0]) + " | " + String(content[i][1]);
    section.appendChild(p);
  }
}

async function getProposal() {
  let section = document.getElementById("proposal");
  section.replaceChildren([]);
  const content = await c5.getProposal();
  console.log(content);
  let len = content.length;
  for (var i = 0; i < len; ++i) {
    let p = document.createElement("p");
    let proposal = content[i][1];
    let Wasm = sha256(proposal["wasm_module"]);
    p.innerText = String(content[i][0]) + " | " + String(proposal["operation_direct"]) + " | " 
      + String(proposal["operation_type"]) + String(proposal["canister_id"]) + " | " + String(Wasm);
    section.appendChild(p);
  }
}

async function create_canister() {
  const id = await c5.create_canister();
  console.log(id);
}

async function start_canister() {
  let id = document.getElementById("canister_id").value;
  await c5.start_canister(Principal.fromText(id));
}

async function stop_canister() {
  let id = document.getElementById("canister_id").value;
  await c5.stop_canister(Principal.fromText(id));
}

async function delete_canister() {
  let id = document.getElementById("canister_id").value;
  await c5.delete_canister(Principal.fromText(id));
}

async function install_code() {
  let id = document.getElementById("canister_id").value;
  let reader = new FileReader();
  let p_path = document.getElementById("make_wasm").files[0];
  reader.readAsArrayBuffer(p_path);
  reader.onload = async function () {
    let p_wasm = new Uint8Array(reader.result);
    p_wasm = sha256(p_wasm);
    await c5.install_code(Principal.fromText(id), p_wasm);
  };
}

async function makeProposal() {
  let p_id = document.getElementById("canister_id").value;
  let p_type = document.getElementById("make_type").value;
  let p_direct = document.getElementById("make_direct").value;
  let p_path = document.getElementById("make_wasm").files[0];
  console.log(p_id, p_type, p_direct, p_path);

  if (p_type === "install_code") {
    let reader = new FileReader();
    reader.readAsArrayBuffer(p_path);
    reader.onload = async function () {
      let p_wasm = new Uint8Array(reader.result);
      p_wasm = sha256(p_wasm);
      await c5.make_proposal_warp(p_direct, p_type, Principal.fromText(p_id), p_wasm);
    };
  } else {
    await c5.make_proposal_warp(p_direct, p_type, Principal.fromText(p_id), []);
  }
}

async function voteProposal() {
  let p_id = Number(document.getElementById("proposal_id").value);
  let p_approve = Boolean(document.getElementById("approve").value);
  await c5.vote_proposal(p_id, p_approve, false);
}

function init() {
  document.getElementById("create").addEventListener("click", create_canister);
  document.getElementById("start").addEventListener("click", start_canister);
  document.getElementById("stop").addEventListener("click", stop_canister);
  document.getElementById("delete").addEventListener("click", delete_canister);
  document.getElementById("install").addEventListener("click", install_code);
  document.getElementById("make").addEventListener("click", makeProposal);
  document.getElementById("vote").addEventListener("click", voteProposal);
  getPrincipal();
  getMember();
  getCanister();
  getProposal();
  setInterval(getMember, 10000);
  setInterval(getCanister, 10000);
  setInterval(getProposal, 10000);
}

window.onload = init;
