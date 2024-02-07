#include "scope_table.h"

class SYMBOL_TABLE
{
private:
    SCOPE_TABLE *currTable;
    int N;

public:
    SYMBOL_TABLE(int n)
    {
        N = n;
        currTable = new SCOPE_TABLE(N);
        currTable->parent = nullptr;
        currTable->setId("1");
    }

    void Enter_Scope()
    {
        
        
        SCOPE_TABLE *newTable = new SCOPE_TABLE(N);

        string currId;
        if (currTable == nullptr)
        {
            currId = "1";
            

            newTable->setId(currId);
            currTable = newTable;
        }
        else
        {
            newTable->parent = currTable;
            currTable->no_of_children++;
            currId = "" + currTable->getId() + "." + to_string(currTable->no_of_children);
            

            newTable->setId(currId);
            currTable = newTable;
        }
        // cout<<"New ScopeTable with id #"<<currId<<" is created\n";
    }

    void Exit_Scope()
    {

        if (currTable == nullptr) {
            cout << "No current scope\n";
            return ;
        }

        SCOPE_TABLE* temp = currTable;
        //cout<<"ScopeTable with id #"<<temp->getId()<<" is removed\n";
        currTable = currTable->parent;
        delete temp;
    }


    bool Insert(string name, string type)
    {
        if (currTable == nullptr)
        {
            currTable = new SCOPE_TABLE(N);
            currTable->setId("1");
        }

        if (!currTable->Insert(name, type))
        {
            // cout<<"< "<<name<<", "<<type<<" > already exist in the current ScopeTable\n";
            return false;
        }
        return true;
    }

    bool Remove(string name)
    {
        if (currTable == nullptr)
        {
            cout << "No current scope" << endl;
            return false;
        }
        return currTable->Delete(name);
    }

    SYMBOL_INFO *Lookup(string name, string type)
    {
        SYMBOL_INFO *found = nullptr;
        SCOPE_TABLE *curr = currTable;

        while (curr != nullptr)
        {
            found = curr->Lookup(name, type);
            if (found != nullptr)
                return found;
            curr = curr->parent;
        }

        return found;
    }

    void Print_Current_ScopeTable(ofstream &logOut)
    {
        currTable->Print(logOut);
    }

    void Print_All_ScopeTable(ofstream &logOut)
    {

        SCOPE_TABLE *curr = currTable;

        while (curr != nullptr)
        {
            logOut << endl << "Scope table #" << curr->getId() << endl;
            
            curr->Print(logOut);
            curr = curr->parent;
        }
    }

    void Print_All_ScopeTable()
    {

        SCOPE_TABLE *curr = currTable;

        while (curr != nullptr)
        {
            cout << endl << "Scope table #" << curr->getId() << endl;
            
            curr->Print();
            curr = curr->parent;
        }
    }

    string getCurrentID(){
        return currTable->getId();
    }

    ~SYMBOL_TABLE()
    {
        SCOPE_TABLE *t = nullptr;
        while (currTable)
        {
            t = this->currTable;
            this->currTable = currTable->parent;
            delete t;
        }
    }
};
