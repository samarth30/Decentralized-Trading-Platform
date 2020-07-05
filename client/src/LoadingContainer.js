import React , {useState , useEffect} from 'react'
import web3 from 'web3';
import App from './App';
import {getWeb3,getContracts} from './utils.js'
const LoadingContainer = () => {
    const [web3,setWeb3] = useState(undefined);
    const [contracts,setContracts] = useState(undefined);
    const [accounts,setAccounts] = useState([]);

    useEffect(() => {
        const init = async()=>{
            const web3 = await getWeb3();
            const contracts = await getContracts();
            const accounts = await web3.eth.getAccounts();
            setWeb3(web3);
            setContracts(contracts);
            setAccounts(accounts);
        }
        init();
    }, [])

    const isReady = ()=>{
        return(
            typeof web3 !== undefined &&
            typeof contracts !== undefined &&
            typeof accounts.length > 0
        )
    }
if(!isReady){
    return (
        <div>
            Loading ...
        </div>
    )
}
 return (
     <App
     web3={web3}
     contracts={contracts}
     accounts = {accounts}
     />
 )  
}

export default LoadingContainer
