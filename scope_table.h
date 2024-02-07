#include "symbol_info.h"

class SCOPE_TABLE
{
private:
    int Hash(string str){
        unsigned long hash = 0;
        int c;

        for (char c : str )
            hash = c + (hash << 6) + (hash << 16) - hash;

        return (int)(hash%N);
    }
    int N;
    string ID;
    SYMBOL_INFO **symbol_infos;

public:
    SCOPE_TABLE *parent;
    int no_of_children;

    SCOPE_TABLE(int n)
    {
        N = n;
        parent = nullptr;
        symbol_infos = new SYMBOL_INFO *[N];
        no_of_children = 0;
        for (int i = 0; i < N; i++)
            symbol_infos[i] = nullptr;
    }

    void setId(string _id) { ID = _id; }

    string getId() { return ID; }

    bool Insert(string name, string type)
    {
        int pos = Hash(name);
        if (symbol_infos[pos] == nullptr)
        {
            symbol_infos[pos] = new SYMBOL_INFO(name, type);
            // cout << "Inserted in Scopetable #"<< ID << " at position " << pos << ", " << 0 <<endl;

            

            return true;
        }
        else
        {
            SYMBOL_INFO *curr = symbol_infos[pos];
            int i = 0;
            while (curr->getName() != name)
            {
                i++;
                if (curr->next != nullptr)
                    curr = curr->next;
                else
                {
                    curr->next = new SYMBOL_INFO(name, type);
                    // cout << "Inserted in Scopetable #"<< ID << " at position " << pos << ", " << i <<endl;
                    
                    return true;
                }
            }
            // cout<<"This word already exists"<<endl;
            return false;
        }
    }

    SYMBOL_INFO *Lookup(string name, string type)
    {

        int pos = Hash(name);      


        if (symbol_infos[pos] == nullptr)
            return nullptr;

        SYMBOL_INFO *curr = symbol_infos[pos];
        //int i = 0;


        
        /*
        while (curr->getName() != name )
        {
            //i++;
            if (curr->next != nullptr)
                curr = curr->next;
            else
                {
                    
                    return nullptr;
                }
        }
        //cout << "Found in Scopetable #" << ID << " at position " << pos << ", " << i << endl;
        return curr;
        */

       while( curr != nullptr ){

        if( curr->getName() == name && curr->getType() == type ) return curr;

        curr = curr->next;    
       }
       return nullptr;
    }

    bool Delete(string name)
    {
        int pos = Hash(name);
        if (symbol_infos[pos] == nullptr)
        {
            cout << "Not Found" << endl;
            return false;
        }
        else
        {
            SYMBOL_INFO *curr = symbol_infos[pos];
            SYMBOL_INFO *temp;
            int i = 0;
            if (curr->getName() == name && curr->next == nullptr)
            {
                delete curr;
                symbol_infos[pos] = nullptr;
            }
            else if (curr->getName() == name && curr->next != nullptr)
            {
                symbol_infos[pos] = curr->next;
                delete curr;
            }
            else
            {

                while (curr->next != nullptr && curr->next->getName() != name)
                {
                    i++;
                    curr = curr->next;
                }
                if (curr->next == nullptr)
                {
                    cout << "Not Found" << endl;
                    return false;
                }
                i++;
                temp = curr->next;
                curr->next = curr->next->next;
                delete temp;
            }

            cout << "Deleted entry at " << pos << ", " << i << endl;
            return true;
        }
    }

    void Print(ofstream &logOut)
    {

        for (int i = 0; i < N; i++)
        {
            logOut << endl;
            logOut << i << " --> ";

            SYMBOL_INFO *curr = symbol_infos[i];

            while (curr != nullptr)
            {
                logOut << "< " << curr->getName() << " : " << curr->getType() << " > ";
                curr = curr->next;
            }
            
        }
        logOut<<endl;
    }


    void Print()
    {

        for (int i = 0; i < N; i++)
        {
            cout << endl;
            cout << i << " --> ";

            SYMBOL_INFO *curr = symbol_infos[i];

            while (curr != nullptr)
            {
                cout << "< " << curr->getName() << " : " << curr->getType() << " > ";
                curr = curr->next;
            }
            
        }
        cout<<endl;
    }
    

    ~SCOPE_TABLE()
    {
        // if(parent == nullptr)
        // cout<<"Destroying the First Scope\n";
        // cout<<"Destroying the ScopeTable\n";
        for (int i = 0; i < N; i++)
        {
            // delete each chain
            SYMBOL_INFO *current = symbol_infos[i];
            while (current)
            {
                SYMBOL_INFO *temp = current->next;
                delete current;
                current = temp;
            }
            symbol_infos[i] = nullptr;
        }
        delete[] symbol_infos;
    }
};

